import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/pet.dart';

class PetRepository {
  final SupabaseClient _client;

  PetRepository(this._client);

  Future<List<Pet>> fetchPets({String? status, String? species}) async {
    try {
      var query = _client.from('pets').select();
      
      if (status != null && status != 'All') {
        query = query.eq('status', status);
      }
      
      if (species != null && species != 'All') {
        // Use ilike for case-insensitive match
        query = query.ilike('species', species);
      }

      // Filter out expired pets (expires_at > now)
      final now = DateTime.now().toIso8601String();
      query = query.gt('expires_at', now);

      // Filter out REUNITED pets (unless status is explicitly requesting them, which 'All' does not imply for feed)
      // If user specifically asks for 'REUNITED' via status param, we should allow it.
      // But if status is 'All' or null (feed), we hide them.
      if (status == null || status == 'All') {
         query = query.neq('status', 'REUNITED');
      }

      final response = await query.order('created_at', ascending: false).limit(50);

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
        .gt('expires_at', now) // Only show non-expired
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((json) => Pet.fromJson(json)).toList();
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
    
    final response = await _client.from('pets').insert({
        'status': status,
        'species': species,
        'pet_name': petName,
        'color_main': color,
        'description': description,
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
  }) async {
    await _client.from('pets').update({
      if (petName != null) 'pet_name': petName,
      if (species != null) 'species': species,
      if (status != null) 'status': status,
      if (sex != null) 'sex': sex,
      if (colorMain != null) 'color_main': colorMain,
      if (description != null) 'description': description,
      if (contactInfo != null) 'contact_info': contactInfo,
      if (reward != null) 'reward': reward,
    }).eq('id', petId);
  }
}
