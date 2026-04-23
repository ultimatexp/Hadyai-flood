import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/pet.dart';
import '../domain/pet_claim.dart';
import '../domain/pet_transfer.dart';
import '../domain/claim_transfer_rules.dart';

class PetRepository {
  final SupabaseClient _client;

  PetRepository(this._client);

  Future<List<Pet>> fetchPets({
    String? status,
    String? species,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('pets').select();
      
      if (status != null && status != 'All') {
        query = query.eq('status', status);
      }
      
      if (species != null && species != 'All') {
        // Use ilike for case-insensitive match
        query = query.ilike('species', species);
      }

      // Keep non-expired pets and legacy rows with null expires_at.
      final now = DateTime.now().toIso8601String();
      query = query.or('expires_at.is.null,expires_at.gt.$now');

      // Filter out REUNITED pets (unless status is explicitly requesting them, which 'All' does not imply for feed)
      // If user specifically asks for 'REUNITED' via status param, we should allow it.
      // But if status is 'All' or null (feed), we hide them.
      if (status == null || status == 'All') {
         query = query.neq('status', 'REUNITED');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final data = response as List<dynamic>;
      return data.map((json) => Pet.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching pets: $e'); 
      rethrow;
    }
  }

  Future<List<Pet>> fetchAdoptablePets() async {
    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from('pets')
        .select()
        .eq('status', 'ADOPTABLE')
        .or('expires_at.is.null,expires_at.gt.$now')
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Pet.fromJson(json)).toList();
  }

  Future<Pet?> fetchPetById(String petId) async {
    final response = await _client.from('pets').select().eq('id', petId).maybeSingle();
    if (response == null) return null;
    return Pet.fromJson(response);
  }

  Future<List<Pet>> fetchUserReports(String userId) async {
    final response = await _client
        .from('pets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Pet.fromJson(json)).toList();
  }

  Future<List<PetClaim>> fetchClaimsForPet(String petId) async {
    final response = await _client
        .from('pet_claims')
        .select()
        .eq('pet_id', petId)
        .order('created_at', ascending: false);
    final data = response as List<dynamic>;
    return data.map((e) => PetClaim.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<PetClaim>> fetchMyClaimsForPet(String petId) async {
    final current = _client.auth.currentUser;
    if (current == null) return [];
    final response = await _client
        .from('pet_claims')
        .select()
        .eq('pet_id', petId)
        .eq('claimant_user_id', current.id)
        .order('created_at', ascending: false);
    final data = response as List<dynamic>;
    return data.map((e) => PetClaim.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<PetTransfer?> fetchPendingTransferForPet(String petId) async {
    final current = _client.auth.currentUser;
    if (current == null) return null;
    final response = await _client
        .from('pet_transfers')
        .select()
        .eq('pet_id', petId)
        .eq('status', 'pending_claimant_confirmation')
        .or('owner_user_id.eq.${current.id},claimant_user_id.eq.${current.id}')
        .maybeSingle();
    if (response == null) return null;
    return PetTransfer.fromJson(Map<String, dynamic>.from(response));
  }

  Future<PetClaim> submitClaim({
    required String petId,
    String? note,
  }) async {
    final current = _client.auth.currentUser;
    if (current == null) {
      throw Exception('Please login to submit a claim');
    }
    final pet = await fetchPetById(petId);
    if (pet == null) throw Exception('Pet not found');
    final ownerUserId = pet.userId;
    if (ownerUserId == null || ownerUserId.isEmpty) {
      throw Exception('This post has no owner account');
    }
    if (ownerUserId == current.id) {
      throw Exception('Owner cannot claim own post');
    }

    final existing = await _client
        .from('pet_claims')
        .select('id,status')
        .eq('pet_id', petId)
        .eq('claimant_user_id', current.id)
        .maybeSingle();
    if (existing != null) {
      throw Exception('You already submitted a claim');
    }

    final inserted = await _client.from('pet_claims').insert({
      'pet_id': petId,
      'owner_user_id': ownerUserId,
      'claimant_user_id': current.id,
      'note': note?.trim().isEmpty ?? true ? null : note?.trim(),
      'status': 'pending',
    }).select().single();

    await _notifyUser(
      userId: ownerUserId,
      title: 'New ownership claim',
      message: 'A user submitted a claim for your pet report.',
      type: 'pet_claim',
      data: {'pet_id': petId, 'claim_id': inserted['id']},
    );

    return PetClaim.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<PetClaim> acceptClaim(String claimId) async {
    final current = _client.auth.currentUser;
    if (current == null) throw Exception('Please login');
    final claim = await _getClaim(claimId);
    if (claim == null) throw Exception('Claim not found');
    final activeTransfer = await _client
        .from('pet_transfers')
        .select('id')
        .eq('pet_id', claim.petId)
        .eq('status', 'pending_claimant_confirmation')
        .maybeSingle();
    final allowed = canOwnerAcceptClaim(
      isOwner: claim.ownerUserId == current.id,
      claimStatus: claim.status,
      hasPendingTransfer: activeTransfer != null,
    );
    if (!allowed) {
      throw Exception('Owner can only accept pending claims without active transfer');
    }

    final updated = await _client
        .from('pet_claims')
        .update({'status': 'accepted'})
        .eq('id', claimId)
        .select()
        .single();

    await _notifyUser(
      userId: claim.claimantUserId,
      title: 'Claim accepted',
      message: 'Owner accepted your claim. Waiting for transfer submission.',
      type: 'pet_claim',
      data: {'pet_id': claim.petId, 'claim_id': claimId, 'status': 'accepted'},
    );

    return PetClaim.fromJson(Map<String, dynamic>.from(updated));
  }

  Future<PetClaim> rejectClaim(String claimId) async {
    final current = _client.auth.currentUser;
    if (current == null) throw Exception('Please login');
    final claim = await _getClaim(claimId);
    if (claim == null) throw Exception('Claim not found');
    final allowed = canOwnerRejectClaim(
      isOwner: claim.ownerUserId == current.id,
      claimStatus: claim.status,
    );
    if (!allowed) {
      throw Exception('Owner can only reject pending claims');
    }

    final updated = await _client
        .from('pet_claims')
        .update({'status': 'rejected'})
        .eq('id', claimId)
        .select()
        .single();

    await _notifyUser(
      userId: claim.claimantUserId,
      title: 'Claim rejected',
      message: 'Owner rejected your claim for this pet.',
      type: 'pet_claim',
      data: {'pet_id': claim.petId, 'claim_id': claimId, 'status': 'rejected'},
    );

    return PetClaim.fromJson(Map<String, dynamic>.from(updated));
  }

  Future<PetTransfer> submitTransferForAcceptedClaim(String claimId) async {
    final current = _client.auth.currentUser;
    if (current == null) throw Exception('Please login');
    final claim = await _getClaim(claimId);
    if (claim == null) throw Exception('Claim not found');
    final activeTransfer = await _client
        .from('pet_transfers')
        .select('id')
        .eq('pet_id', claim.petId)
        .eq('status', 'pending_claimant_confirmation')
        .maybeSingle();
    final allowed = canOwnerSubmitTransfer(
      isOwner: claim.ownerUserId == current.id,
      claimStatus: claim.status,
      hasPendingTransfer: activeTransfer != null,
    );
    if (!allowed) {
      throw Exception('Owner can only submit transfer for accepted claim');
    }

    final inserted = await _client.from('pet_transfers').insert({
      'pet_id': claim.petId,
      'claim_id': claim.id,
      'owner_user_id': claim.ownerUserId,
      'claimant_user_id': claim.claimantUserId,
      'status': 'pending_claimant_confirmation',
      'owner_submitted_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    }).select().single();

    await _notifyUser(
      userId: claim.claimantUserId,
      title: 'Transfer submitted',
      message: 'Owner submitted transfer. Please confirm to complete handoff.',
      type: 'pet_transfer',
      data: {'pet_id': claim.petId, 'claim_id': claim.id, 'transfer_id': inserted['id']},
    );

    return PetTransfer.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<PetTransfer> confirmTransfer(String transferId) async {
    final current = _client.auth.currentUser;
    if (current == null) throw Exception('Please login');

    final transferRow = await _client
        .from('pet_transfers')
        .select()
        .eq('id', transferId)
        .maybeSingle();
    if (transferRow == null) throw Exception('Transfer not found');
    final transfer = PetTransfer.fromJson(Map<String, dynamic>.from(transferRow));

    final allowed = canClaimantConfirmTransfer(
      isDesignatedClaimant: transfer.claimantUserId == current.id,
      transferStatus: transfer.status,
    );
    if (!allowed) {
      throw Exception('Only designated claimant can confirm pending transfer');
    }

    final now = DateTime.now().toIso8601String();
    final updated = await _client
        .from('pet_transfers')
        .update({
          'status': 'confirmed',
          'confirmed_at': now,
        })
        .eq('id', transferId)
        .select()
        .single();

    await _client.from('pets').update({
      'user_id': current.id,
      'status': 'REUNITED',
    }).eq('id', transfer.petId);

    await _notifyUser(
      userId: transfer.ownerUserId,
      title: 'Transfer confirmed',
      message: 'Claimant confirmed transfer. Pet ownership has been updated.',
      type: 'pet_transfer',
      data: {'pet_id': transfer.petId, 'transfer_id': transfer.id, 'status': 'confirmed'},
    );

    return PetTransfer.fromJson(Map<String, dynamic>.from(updated));
  }

  Future<List<Pet>> fetchLatestFoundPets({int limit = 5}) async {
    final response = await _client
        .from('pets')
        .select()
        .eq('status', 'FOUND')
        .order('created_at', ascending: false)
        .limit(limit);

    final data = response as List<dynamic>;
    return data.map((json) => Pet.fromJson(json)).toList();
  }

  Future<Map<String, int>> fetchStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

    try {
      // 1. Today Found: Pets reported as FOUND today
      final todayFound = await _client
          .from('pets')
          .count(CountOption.exact)
          .eq('status', 'FOUND')
          .gte('created_at', todayStart);
      
      // 2. Today Search: Pets reported as LOST today (people searching)
      final todaySearch = await _client
          .from('pets')
          .count(CountOption.exact)
          .eq('status', 'LOST')
          .gte('created_at', todayStart);

      // 3. Today Success: Mocked for now (Reunited)
      // Ideally this would measure status changes from LOST to FOUND/ADOPTED
      // For now we'll mock it or use a fraction of found
      final todaySuccess = (todayFound / 2).round(); 

      return {
        'today_found': todayFound,
        'today_search': todaySearch,
        'today_success': todaySuccess,
      };
    } catch (e) {
      print('Error fetching stats: $e');
      // Fallback to 0 if error
      return {
        'today_found': 0,
        'today_search': 0,
        'today_success': 0,
      };
    }
  }

  // New method for reporting
  Future<void> reportPet({
    required String status,
    required String species,
    required String color,
    String? petName,
    String? description,
    String? sex,
    double? lat,
    double? lng,
    String? contactInfo,
    String? reward,
    DateTime? lastSeenDate,
    required List<dynamic> imageFiles, // List<XFile> or List<File>
  }) async {
    List<String> imageUrls = [];
    
    // 1. Upload Images
    if (imageFiles.isEmpty) {
      throw Exception('At least one image is required for reporting a pet.');
    }

    try {
      for (var imageFile in imageFiles) {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.path.split('.').last;
        final fileName = 'pets/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

        await _client.storage.from('sos-photos').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );

        final url = _client.storage.from('sos-photos').getPublicUrl(fileName);
        imageUrls.add(url);
      }
    } catch (e) {
      print('Error uploading images: $e');
      throw Exception('Failed to upload images: $e');
    }

    // 2. Insert to DB with 180-day expiration
    final expiresAt = DateTime.now().add(const Duration(days: 180));
    final descTrimmed = description?.trim();
    final descriptionForDb =
        (descTrimmed == null || descTrimmed.isEmpty) ? null : descTrimmed;

    final response = await _client.from('pets').insert({
        'status': status,
        'species': species,
        'pet_name': petName,
        'color_main': color,
        'description': descriptionForDb,
        'sex': sex?.toLowerCase(),
        'lat': lat,
        'lng': lng,
        'contact_info': contactInfo,
        'reward': reward,
        'last_seen_at': lastSeenDate?.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'image_url': imageUrls.first, // Primary image
        'images': imageUrls, // All images
        'user_id': _client.auth.currentUser?.id, 
    }).select();
  }

  Future<void> updatePet({
    required String petId,
    String? petName,
    String? species,
    String? status,
    String? sex,
    String? colorMain,
    String? description,
    String? contactInfo,
    double? reward,
    String? breed,
    String? marks,
    /// Overrides `color` only (web column); use with [colorMain] for full parity.
    String? legacyColor,
  }) async {
    final updates = <String, dynamic>{};
    if (petName != null) updates['pet_name'] = petName;
    if (species != null) updates['species'] = species;
    if (status != null) updates['status'] = status;
    if (sex != null) updates['sex'] = sex;
    if (colorMain != null) {
      updates['color_main'] = colorMain;
      updates['color'] = colorMain;
    }
    if (legacyColor != null) updates['color'] = legacyColor;
    if (description != null) updates['description'] = description;
    if (contactInfo != null) updates['contact_info'] = contactInfo;
    if (reward != null) updates['reward'] = reward;
    if (breed != null) updates['breed'] = breed;
    if (marks != null) updates['marks'] = marks;
    if (updates.isEmpty) return;
    await _client.from('pets').update(updates).eq('id', petId);
  }

  // UGC: Report Content
  Future<void> reportContent({
    required String reporterId,
    required String entityId,
    required String entityType,
    required String reason,
    String? reportedUserId,
  }) async {
    await _client.from('reports').insert({
      'reporter_id': reporterId,
      'entity_id': entityId,
      'entity_type': entityType,
      'reason': reason,
      'reported_user_id': reportedUserId, 
      'status': 'pending',
    });
  }

  // UGC: Block User
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await _client.from('blocked_users').insert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });
  }

  // UGC: Fetch Blocked Users
  Future<List<String>> fetchBlockedUsers(String userId) async {
    final response = await _client
        .from('blocked_users')
        .select('blocked_id')
        .eq('blocker_id', userId);
    
    // Check if response is null or empty
    if (response == null) return [];

    final data = response as List<dynamic>;
    return data.map((item) => item['blocked_id'] as String).toList();
  }

  Future<PetClaim?> _getClaim(String claimId) async {
    final row = await _client.from('pet_claims').select().eq('id', claimId).maybeSingle();
    if (row == null) return null;
    return PetClaim.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> _notifyUser({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'is_read': false,
        'data': data ?? <String, dynamic>{},
      });
    } catch (_) {
      // non-blocking
    }
  }
}
