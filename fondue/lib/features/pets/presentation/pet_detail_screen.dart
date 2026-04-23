import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:fondue/l10n/app_localizations.dart';
import 'package:fondue/l10n/app_localizations_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/constants.dart';
import '../domain/pet.dart';
import '../domain/pet_claim.dart';
import '../domain/pet_transfer.dart';
import '../domain/pet_matcher_service.dart';
import 'pet_providers.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/presentation/chat_detail_screen.dart';
import 'map_view_screen.dart';
import 'widgets/pet_share_card.dart';
import 'pet_l10n_helpers.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  bool _isCheckingMatches = false;
  int _currentImageIndex = 0;
  late Pet _pet;
  bool _showContactInfo = false;
  bool _reportDetailsExpanded = false;
  bool _claimLoading = false;
  List<PetClaim> _claims = const [];
  PetTransfer? _pendingTransfer;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshClaimTransferState();
    });
  }

  bool get _isOwner {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null && _pet.userId == user.id;
  }

  bool get _isClaimant {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    return _claims.any((c) => c.claimantUserId == user.id);
  }

  Future<void> _refreshClaimTransferState() async {
    if (!mounted) return;
    setState(() => _claimLoading = true);
    try {
      final repo = ref.read(petRepositoryProvider);
      final claims = await repo.fetchClaimsForPet(_pet.id);
      final pendingTransfer = await repo.fetchPendingTransferForPet(_pet.id);
      if (!mounted) return;
      setState(() {
        _claims = claims;
        _pendingTransfer = pendingTransfer;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _claims = const [];
        _pendingTransfer = null;
      });
    } finally {
      if (mounted) setState(() => _claimLoading = false);
    }
  }

  Future<void> _showClaimDialog() async {
    final current = Supabase.instance.client.auth.currentUser;
    if (current == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
      }
      return;
    }
    if (_isOwner) return;
    final ctrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Claim this pet'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add proof details (optional): marks, photos, behaviors...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Submit claim'),
          ),
        ],
      ),
    );
    if (note == null) return;
    try {
      final repo = ref.read(petRepositoryProvider);
      await repo.submitClaim(petId: _pet.id, note: note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim submitted')),
        );
      }
      await _refreshClaimTransferState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit claim: $e')),
        );
      }
    }
  }

  Future<void> _acceptClaim(String claimId) async {
    try {
      final repo = ref.read(petRepositoryProvider);
      await repo.acceptClaim(claimId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim accepted')),
        );
      }
      await _refreshClaimTransferState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept claim: $e')),
        );
      }
    }
  }

  Future<void> _rejectClaim(String claimId) async {
    try {
      final repo = ref.read(petRepositoryProvider);
      await repo.rejectClaim(claimId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim rejected')),
        );
      }
      await _refreshClaimTransferState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject claim: $e')),
        );
      }
    }
  }

  Future<void> _submitTransfer(String claimId) async {
    try {
      final repo = ref.read(petRepositoryProvider);
      await repo.submitTransferForAcceptedClaim(claimId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer submitted. Waiting claimant confirmation.')),
        );
      }
      await _refreshClaimTransferState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit transfer: $e')),
        );
      }
    }
  }

  Future<void> _confirmTransfer(String transferId) async {
    try {
      final repo = ref.read(petRepositoryProvider);
      await repo.confirmTransfer(transferId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer confirmed. Ownership updated.')),
        );
      }
      await _refreshClaimTransferState();
      ref.invalidate(lostPetsProvider);
      ref.invalidate(paginatedLostPetsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm transfer: $e')),
        );
      }
    }
  }

  void _nextImage() {
    if (_pet.images.isNotEmpty && _currentImageIndex < _pet.images.length - 1) {
      setState(() => _currentImageIndex++);
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() => _currentImageIndex--);
    }
  }

  String? get _currentImageUrl {
    if (_pet.images.isNotEmpty) {
      return _pet.images[_currentImageIndex];
    }
    return _pet.imageUrl;
  }

  String _formatCountdown(BuildContext context, Duration duration) {
    final l10n = context.l10n;
    if (duration.isNegative) return l10n.petDetailCountdownExpired;
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) return l10n.petDetailDurationDaysHours(days, hours);
    if (hours > 0) return l10n.petDetailDurationHoursMinutes(hours, minutes);
    return l10n.petDetailDurationMinutes(minutes);
  }

  bool get _isExpired {
    if (_pet.expiresAt == null) return false;
    return _pet.expiresAt!.isBefore(DateTime.now());
  }

  Duration? get _timeRemaining {
    if (_pet.expiresAt == null) return null;
    return _pet.expiresAt!.difference(DateTime.now());
  }

  /// DB stores lowercase sex; edit form uses `Male` / `Female` / `Unknown` keys for `localizedSex`.
  static String _sexToFormValue(String? sex) {
    switch ((sex ?? '').toLowerCase().trim()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      default:
        return 'Unknown';
    }
  }

  static String _sexFormValueToDb(String form) {
    switch (form) {
      case 'Male':
        return 'male';
      case 'Female':
        return 'female';
      default:
        return 'unknown';
    }
  }

  void _showEditDialog() {
    if (!_isOwner) return;

    final nameController = TextEditingController(text: _pet.name ?? '');
    final breedController = TextEditingController(text: _pet.breed ?? '');
    final marksController = TextEditingController(text: _pet.marks ?? _pet.uniqueMarks ?? '');
    final descController = TextEditingController(text: _pet.description ?? '');
    final colorController = TextEditingController(
      text: _pet.colorMain ?? _pet.legacyColor ?? '',
    );
    final contactController = TextEditingController(text: _pet.contactInfo ?? '');
    String selectedStatus = _pet.status;
    String selectedSex = _sexToFormValue(_pet.sex);

    void disposeControllers() {
      nameController.dispose();
      breedController.dispose();
      marksController.dispose();
      descController.dispose();
      colorController.dispose();
      contactController.dispose();
    }

    var saving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final d = AppLocalizations.of(ctx)!;

            return AlertDialog(
              title: Text(d.petDetailEditTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: d.petDetailLabelPetName),
                      enabled: !saving,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(labelText: d.petDetailLabelStatus),
                      items: ['LOST', 'FOUND', 'REUNITED']
                          .map((s) => DropdownMenuItem(value: s, child: Text(localizedPetStatus(ctx, s))))
                          .toList(),
                      onChanged: saving
                          ? null
                          : (v) => setDialogState(() => selectedStatus = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSex,
                      decoration: InputDecoration(labelText: d.petDetailLabelSex),
                      items: ['Male', 'Female', 'Unknown']
                          .map((s) => DropdownMenuItem(value: s, child: Text(localizedSex(ctx, s))))
                          .toList(),
                      onChanged: saving
                          ? null
                          : (v) => setDialogState(() => selectedSex = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: colorController,
                      decoration: InputDecoration(labelText: d.petDetailLabelColor),
                      enabled: !saving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: breedController,
                      decoration: const InputDecoration(
                        labelText: 'Breed',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !saving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: marksController,
                      decoration: const InputDecoration(
                        labelText: 'Marks / identifying signs',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      enabled: !saving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(labelText: d.petDetailLabelDescription),
                      maxLines: 3,
                      enabled: !saving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactController,
                      decoration: InputDecoration(labelText: d.petDetailLabelContact),
                      enabled: !saving,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: Text(d.settingsCancel),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          final updatedMsg = context.l10n.petDetailPetUpdatedSnack;
                          final repo = ref.read(petRepositoryProvider);
                          try {
                            await repo.updatePet(
                              petId: _pet.id,
                              petName: nameController.text.trim().isNotEmpty
                                  ? nameController.text.trim()
                                  : null,
                              status: selectedStatus,
                              sex: _sexFormValueToDb(selectedSex),
                              colorMain: colorController.text.trim().isNotEmpty
                                  ? colorController.text.trim()
                                  : null,
                              description: descController.text.trim().isNotEmpty
                                  ? descController.text.trim()
                                  : null,
                              contactInfo: contactController.text.trim().isNotEmpty
                                  ? contactController.text.trim()
                                  : null,
                              breed: breedController.text.trim().isNotEmpty
                                  ? breedController.text.trim()
                                  : null,
                              marks: marksController.text.trim().isNotEmpty
                                  ? marksController.text.trim()
                                  : null,
                            );
                            final fresh = await repo.fetchPetById(_pet.id);
                            if (!mounted) return;
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            if (fresh != null) {
                              setState(() => _pet = fresh);
                            }
                            ref.invalidate(lostPetsProvider);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(updatedMsg)),
                            );
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() => saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.l10n.petDetailGenericError(e.toString()))),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.accentOrange),
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(d.petDetailSave),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(disposeControllers);
  }

  void _showArchiveDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final d = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  d.petDetailArchiveSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  d.petDetailArchiveSheetSubtitle,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.pets, color: AppTheme.primaryGreen),
                  ),
                  title: Text(
                    d.petDetailArchiveFoundTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(d.petDetailArchiveFoundSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _markAsReunited();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: Text(
                    d.petDetailArchiveDeleteTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  subtitle: Text(d.petDetailArchiveDeleteSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete();
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(d.settingsCancel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markAsReunited() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(d.petDetailMarkFoundTitle),
          content: Text(d.petDetailMarkFoundBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(d.settingsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: Text(d.petDetailMarkReunitedButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(petRepositoryProvider);
        await repo.updatePet(petId: _pet.id, status: 'REUNITED');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.petDetailReunitedSnack),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(lostPetsProvider);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.petDetailGenericError(e.toString()))),
          );
        }
      }
    }
  }

  void _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(d.petDetailDeletePostTitle),
          content: Text(d.petDetailDeletePostBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(d.settingsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(d.settingsDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client
            .from('pets')
            .delete()
            .eq('id', _pet.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.petDetailPostDeletedSnack)),
          );
          ref.invalidate(lostPetsProvider);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.petDetailGenericError(e.toString()))),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasMultipleImages = _pet.images.length > 1;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Hero Image Header with Navigation
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () => PetShareCard.showPreviewThenShare(context, _pet),
                tooltip: l10n.petDetailShareImageTooltip,
              ),
              if (_isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.archive_outlined, color: Colors.white),
                  onPressed: _showArchiveDialog,
                  tooltip: l10n.petDetailArchiveTooltip,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _showEditDialog,
                  tooltip: l10n.petDetailEditTooltip,
                ),
              ] else ...[
                 PopupMenuButton<String>(
                   onSelected: (value) {
                     if (value == 'report') _reportPost();
                     if (value == 'block') _blockUser();
                   },
                   itemBuilder: (menuContext) {
                     final m = AppLocalizations.of(menuContext)!;
                     return [
                       PopupMenuItem(
                         value: 'report',
                         child: Row(
                           children: [
                             const Icon(Icons.flag_outlined, color: Colors.orange),
                             const SizedBox(width: 8),
                             Text(m.petDetailReportPost),
                           ],
                         ),
                       ),
                       PopupMenuItem(
                         value: 'block',
                         child: Row(
                           children: [
                             const Icon(Icons.block, color: Colors.red),
                             const SizedBox(width: 8),
                             Text(m.petDetailBlockUser),
                           ],
                         ),
                       ),
                     ];
                   },
                 ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image with Hero + PageView for swipe
                  if (hasMultipleImages)
                    PageView.builder(
                      itemCount: _pet.images.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final url = _pet.images[index];
                        // Only first image gets the Hero for smooth transition
                        final imageWidget = Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.pets, size: 80, color: Colors.grey),
                          ),
                        );
                        if (index == 0) {
                          return Hero(
                            tag: 'pet-image-${_pet.id}',
                            child: imageWidget,
                          );
                        }
                        return imageWidget;
                      },
                    )
                  else
                    Hero(
                      tag: 'pet-image-${_pet.id}',
                      child: _currentImageUrl != null
                          ? Image.network(
                              _currentImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
                              ),
                            )
                          : Container(color: Colors.grey[300]),
                    ),

                  // Gradient overlay for readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Animated Page Indicator Dots
                  if (hasMultipleImages)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pet.images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: index == _currentImageIndex ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: index == _currentImageIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _pet.status == 'LOST' ? Colors.red : AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          localizedPetStatus(context, _pet.status),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pet.name ?? _pet.species,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                      ),
                    ],
                  ),

                  // Photo count indicator
                  if (hasMultipleImages)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.petDetailPhotoOf(_currentImageIndex + 1, _pet.images.length),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),

                  // Expiry Countdown Banner
                  if (_pet.expiresAt != null)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isExpired 
                            ? Colors.grey[300] 
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isExpired 
                              ? Colors.grey 
                              : Colors.orange.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isExpired ? Icons.timer_off : Icons.timer,
                            color: _isExpired 
                                ? Colors.grey[700] 
                                : Colors.orange.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isExpired ? l10n.petDetailReportExpiredTitle : l10n.petDetailExpiresInLabel,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _isExpired ? l10n.petDetailReportExpiredBody : _formatCountdown(context, _timeRemaining!),
                                  style: TextStyle(
                                    color: _isExpired 
                                        ? Colors.grey[700] 
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Info Grid
                  _buildInfoGrid(context, l10n),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    l10n.petDetailDescriptionHeading,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_pet.description?.trim().isNotEmpty ?? false)
                        ? _pet.description!.trim()
                        : l10n.petDetailNoDescription,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                  ),

                  const SizedBox(height: 24),
                  _buildExtendedWebFields(context),

                  const SizedBox(height: 24),

                  // Location Map
                  if (_pet.lat != null && _pet.lng != null) ...[
                    Text(
                      l10n.petDetailLastSeenHeading,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_pet.lat!, _pet.lng!),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}@2x.png?key=${AppConstants.mapTilerKey}',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_pet.lat!, _pet.lng!),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // See on Map Overlay Button
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Material(
                              color: Colors.white,
                              elevation: 4,
                              borderRadius: BorderRadius.circular(30),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => MapViewScreen(initialPet: _pet)),
                                  );
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.map, size: 16, color: AppTheme.primaryGreen),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.petDetailSeeOnMap,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Owner Card
                  _buildOwnerCard(context, l10n),

                  const SizedBox(height: 16),
                  _buildClaimTransferSection(context),

                  // Post ID
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8),
                      child: SelectableText(
                        l10n.petDetailPostId(_pet.id),
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                    ),
                  ),

                  // Safe Area padding
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? Colors.black54 : Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white54,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context, AppLocalizations l10n) {
    final sx = _pet.sex?.toLowerCase();
    final sexIcon = sx == 'female' ? Icons.female : Icons.male;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildInfoItem(Icons.pets, l10n.petDetailInfoSpecies, _pet.species),
        if (_pet.sex != null && sx != 'unknown')
          _buildInfoItem(
            sexIcon,
            l10n.petDetailInfoSex,
            localizedSex(context, _pet.sex!),
          ),
        if (_pet.breed != null && _pet.breed!.trim().isNotEmpty)
          _buildInfoItem(Icons.category_outlined, 'Breed', _pet.breed!.trim()),
        if (_pet.colorMain != null && _pet.colorMain!.trim().isNotEmpty)
          _buildInfoItem(Icons.palette, l10n.petDetailInfoColor, _pet.colorMain!),
      ],
    );
  }

  static const int _maxJsonPreviewLen = 280;

  String? _truncatePreview(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    if (t.length <= _maxJsonPreviewLen) return t;
    return '${t.substring(0, _maxJsonPreviewLen)}…';
  }

  Widget _buildExtendedWebFields(BuildContext context) {
    if (!_pet.hasExtendedAttributes) return const SizedBox.shrink();

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[900]),
              ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];

    void add(String label, String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return;
      rows.add(row(label, v));
    }

    add('Secondary color', _pet.colorSecondary);
    add('Pattern', _pet.colorPattern);
    add('Fur length', _pet.furLength);
    add('Eye color', _pet.eyeColor);
    add('Body size', _pet.bodySize);
    add('Collar color', _pet.collarColor);
    add('Unique marks', _pet.uniqueMarks);
    if (_pet.marks != null && _pet.marks!.trim().isNotEmpty && _pet.marks != _pet.uniqueMarks) {
      add('Marks', _pet.marks);
    }
    add('Web color (legacy)', _pet.legacyColor);
    add('Pet type (legacy)', _pet.petType);
    if (_pet.lastSeenAt != null) {
      rows.add(row('Last seen', _pet.lastSeenAt!.toLocal().toString()));
    }
    add('EXIF time', _pet.exifTime);
    if (_pet.exifLocation != null && _pet.exifLocation!.isNotEmpty) {
      rows.add(row('EXIF location', _pet.exifLocation.toString()));
    }
    for (final e in _pet.characteristicEntries) {
      rows.add(row(e.key, e.value));
    }
    final dc = _truncatePreview(_pet.dominantColorsJson);
    if (dc != null) rows.add(row('Dominant colors', dc));
    final cp = _truncatePreview(_pet.colorPercentagesJson);
    if (cp != null) rows.add(row('Color %', cp));
    final lc = _truncatePreview(_pet.labColorsJson);
    if (lc != null) rows.add(row('Lab colors', lc));
    if (_pet.hasImageEmbedding) {
      rows.add(row('Image embedding', 'Stored (used for search)'));
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: _reportDetailsExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _reportDetailsExpanded = expanded);
        },
        title: Text(
          'Report details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        children: rows,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(BuildContext context, AppLocalizations l10n) {
    // If user is owner, show management card
    if (_isOwner) {
      if (_pet.status == 'LOST') {
        return Container(
          width: double.infinity, 
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50], 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_accounts, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.petDetailYourPostTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                        ),
                        Text(
                          l10n.petDetailYourPostSubtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showEditDialog,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: Text(l10n.petDetailEditTooltip),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade800,
                    side: BorderSide(color: Colors.blue.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Recheck Database Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCheckingMatches ? null : _checkDatabaseForMatches,
                  icon: _isCheckingMatches 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.saved_search),
                  label: Text(_isCheckingMatches ? l10n.petDetailCheckingDatabase : l10n.petDetailRecheckMatches),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.blue[300],
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Owner but not LOST (e.g. Found/Adoptable/Reunited)
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.petDetailOwnerOfPost,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: Text(l10n.petDetailEditTooltip),
              ),
            ],
          ),
        );
      }
    }

    // Standard Owner Card for Viewers
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getOwnerProfile(),
      builder: (context, snapshot) {
        final ownerName = snapshot.data?['full_name'] as String? ?? l10n.petDetailDefaultOwnerName;
        final ownerAvatar = snapshot.data?['avatar_url'] as String?;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Info Row
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: ownerAvatar != null
                        ? NetworkImage(ownerAvatar)
                        : NetworkImage('https://i.pravatar.cc/150?u=${_pet.userId}'),
                  ),
                  const SizedBox(width: 12),
                  // Owner Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.petDetailPostOwnedBy,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ownerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  // Chat Now Button - Primary CTA
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isOwner ? null : _startChat,
                      icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                      label: Text(
                        l10n.petDetailChatNow,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contact Owner Button - Phone Call
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pet.contactInfo != null && _pet.contactInfo!.isNotEmpty
                          ? _callOwner
                          : null,
                      icon: const Icon(Icons.phone, size: 20),
                      label: Text(
                        l10n.petDetailContact,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentOrange,
                        side: BorderSide(
                          color: _pet.contactInfo != null && _pet.contactInfo!.isNotEmpty
                              ? AppTheme.accentOrange
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClaimTransferSection(BuildContext context) {
    final current = Supabase.instance.client.auth.currentUser;
    if (current == null) return const SizedBox.shrink();

    final myClaim = _claims.cast<PetClaim?>().firstWhere(
          (c) => c?.claimantUserId == current.id,
          orElse: () => null,
        );
    final acceptedClaim = _claims.cast<PetClaim?>().firstWhere(
          (c) => c?.status == 'accepted',
          orElse: () => null,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.indigo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ownership claim & transfer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (_claimLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _refreshClaimTransferState,
                tooltip: 'Refresh claim status',
              ),
            ],
          ),
          if (!_isOwner) ...[
            const SizedBox(height: 8),
            if (myClaim == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showClaimDialog,
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Claim this pet'),
                ),
              )
            else
              Text(
                'Your claim status: ${myClaim.status.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          ],
          if (_isOwner) ...[
            const SizedBox(height: 8),
            if (_claims.isEmpty)
              Text(
                'No claims yet.',
                style: TextStyle(color: Colors.grey[700]),
              )
            else
              ..._claims.map((claim) {
                final canAcceptReject = claim.status == 'pending';
                final canTransfer = claim.status == 'accepted' &&
                    (_pendingTransfer == null ||
                        _pendingTransfer!.status != 'pending_claimant_confirmation');
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Claimant: ${claim.claimantUserId.substring(0, 8)}...  |  ${claim.status.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      if (claim.note != null && claim.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(claim.note!, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (canAcceptReject)
                            OutlinedButton(
                              onPressed: () => _acceptClaim(claim.id),
                              child: const Text('Accept'),
                            ),
                          if (canAcceptReject)
                            OutlinedButton(
                              onPressed: () => _rejectClaim(claim.id),
                              child: const Text('Reject'),
                            ),
                          if (canTransfer)
                            ElevatedButton(
                              onPressed: () => _submitTransfer(claim.id),
                              child: const Text('Submit transfer'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
          if (_pendingTransfer != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transfer status: ${_pendingTransfer!.status}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (_pendingTransfer!.claimantUserId == current.id &&
                      _pendingTransfer!.status == 'pending_claimant_confirmation')
                    FilledButton.icon(
                      onPressed: () => _confirmTransfer(_pendingTransfer!.id),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirm transfer'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _checkDatabaseForMatches() async {
    if (_isCheckingMatches) return;
    
    setState(() => _isCheckingMatches = true);
    
    try {
      final matcher = ref.read(petMatcherProvider);
      final matches = await matcher.findMatchesForPet(_pet);
      
      if (!mounted) return;
      
      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.petDetailNoNewMatches)),
        );
      } else {
        _showMatchResults(matches);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.petDetailErrorCheckingMatches(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingMatches = false);
      }
    }
  }

  void _showMatchResults(List<Map<String, dynamic>> matches) {
    showDialog(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Flexible(child: Text(d.petDetailMatchResultsTitle(matches.length))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: matches.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (ctx, index) {
                final match = matches[index];
                final foundPet = match['foundPet'] as Pet;
                final score = ((match['score'] as double) * 100).toInt();

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: foundPet.imageUrl != null
                        ? Image.network(foundPet.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                        : Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.pets)),
                  ),
                  title: Text(d.petDetailMatchListTileTitle(foundPet.species, score)),
                  subtitle: Text(foundPet.description ?? d.petFeedNoDescription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PetDetailScreen(pet: foundPet)),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(d.petDetailClose),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getOwnerProfile() async {
    if (_pet.userId == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', _pet.userId!)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> _startChat() async {
    if (_pet.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.petDetailChatNoOwner)),
      );
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.petDetailChatLoginRequired)),
      );
      return;
    }

    final defaultOwnerLabel = context.l10n.petDetailDefaultOwnerName;
    try {
      final chatRepo = ChatRepository(Supabase.instance.client);
      final conversationId = await chatRepo.getOrCreateConversation(
        otherUserId: _pet.userId!,
        petId: _pet.id,
      );

      if (mounted && conversationId != null) {
        // Get owner profile for name
        final ownerProfile = await _getOwnerProfile();
        final ownerName = ownerProfile?['full_name'] as String? ?? defaultOwnerLabel;
        final ownerAvatar = ownerProfile?['avatar_url'] as String? ?? 
            'https://i.pravatar.cc/150?u=${_pet.userId}';

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: conversationId,
              name: ownerName,
              avatar: ownerAvatar,
              phoneNumber: _pet.contactInfo,
              petStatus: _pet.status,
              petName: _pet.name,
              otherUserId: _pet.userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.petDetailChatFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _callOwner() async {
    if (_pet.contactInfo == null || _pet.contactInfo!.isEmpty) return;

    // Clean phone number - remove non-digit characters except +
    final phone = _pet.contactInfo!.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$phone');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.petDetailCannotCall)),
        );
      }
    }
  }

  void _reportPost() async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(d.petDetailReportDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(d.petDetailReportDialogPrompt),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: d.petDetailReportHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(d.settingsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, reasonController.text),
              child: Text(d.petDetailReportSubmit),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        final repo = ref.read(petRepositoryProvider);
        final currentUser = Supabase.instance.client.auth.currentUser;
        
        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.petDetailReportLoginRequired)),
            );
          }
          return;
        }

        await repo.reportContent(
          reporterId: currentUser.id,
          entityId: _pet.id,
          entityType: 'pet',
          reason: result,
          reportedUserId: _pet.userId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.petDetailReportThanks)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.petDetailReportError(e.toString()))),
          );
        }
      }
    }
  }

  void _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final d = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(d.petDetailBlockDialogTitle),
          content: Text(d.petDetailBlockDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(d.settingsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(d.petDetailBlockSubmit),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(petRepositoryProvider);
        final currentUser = Supabase.instance.client.auth.currentUser;
        
        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.petDetailBlockLoginRequired)),
            );
          }
          return;
        }

        if (_pet.userId == null) return;

        await repo.blockUser(
          blockerId: currentUser.id,
          blockedId: _pet.userId!,
        );

        // Refresh providers to hide blocked content
        ref.invalidate(blockedUsersProvider);
        ref.invalidate(lostPetsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.petDetailUserBlocked)),
          );
          Navigator.pop(context); // Close detail screen as context is now hidden
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.petDetailBlockError(e.toString()))),
          );
        }
      }
    }
  }
}
