import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fondue/l10n/app_localizations.dart';
import 'package:fondue/l10n/app_localizations_context.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/pet.dart';
import '../domain/pet_matcher_service.dart';
import 'pet_detail_screen.dart';

class PotentialMatchesScreen extends ConsumerStatefulWidget {
  const PotentialMatchesScreen({super.key});

  @override
  ConsumerState<PotentialMatchesScreen> createState() => _PotentialMatchesScreenState();
}

class _PotentialMatchesScreenState extends ConsumerState<PotentialMatchesScreen> {
  List<Map<String, dynamic>>? _matches;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matcher = ref.read(petMatcherProvider);
      final matches = await matcher.findMatchesForUser();

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.potentialMatchesScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches,
            tooltip: l10n.potentialMatchesRefreshTooltip,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.potentialMatchesSearching),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(l10n.potentialMatchesErrorLine(_errorMessage!)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMatches,
              child: Text(l10n.potentialMatchesRetry),
            ),
          ],
        ),
      );
    }

    if (_matches == null || _matches!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              l10n.potentialMatchesEmptyTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                l10n.potentialMatchesEmptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadMatches,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.potentialMatchesCheckAgain),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _matches!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final match = _matches![index];
          final lostPet = match['lostPet'] as Pet;
          final foundPet = match['foundPet'] as Pet;
          final score = ((match['score'] as double) * 100).toInt();

          return _buildMatchCard(context, lostPet, foundPet, score, index);
        },
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Pet lostPet, Pet foundPet, int score, int index) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getScoreColor(score).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, color: _getScoreColor(score)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.potentialMatchesCardLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.potentialMatchesScorePercent(score),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildPetColumn(context, lostPet, l10n.potentialMatchesYourLostPet, Colors.red),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey[400]),
                ),
                Expanded(
                  child: _buildPetColumn(context, foundPet, l10n.potentialMatchesFoundPet, AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PetDetailScreen(pet: foundPet)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.potentialMatchesViewFoundPet),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _dismissMatch(lostPet, foundPet, index),
                  icon: Icon(Icons.visibility_off, size: 18, color: Colors.grey[600]),
                  label: Text(
                    l10n.potentialMatchesDismiss,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dismissMatch(Pet lostPet, Pet foundPet, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(dialogL10n.potentialMatchesHideDialogTitle),
          content: Text(dialogL10n.potentialMatchesHideDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dialogL10n.settingsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(dialogL10n.potentialMatchesHideMatch),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final matcher = ref.read(petMatcherProvider);
    final success = await matcher.dismissMatch(lostPet.id, foundPet.id);

    if (mounted) {
      final l10n = context.l10n;
      if (success) {
        setState(() {
          _matches!.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.potentialMatchesHiddenSnack)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.potentialMatchesHideFailedSnack)),
        );
      }
    }
  }

  Widget _buildPetColumn(BuildContext context, Pet pet, String label, Color labelColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: labelColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: pet.imageUrl != null
              ? Image.network(
                  pet.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
        const SizedBox(height: 8),
        Text(
          pet.name ?? pet.species,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (pet.colorMain != null)
          Text(
            pet.colorMain!,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.pets, color: Colors.grey[400], size: 32),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.amber;
  }
}
