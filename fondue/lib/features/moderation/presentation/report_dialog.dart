import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/moderation_providers.dart';

class ReportDialog extends ConsumerStatefulWidget {
  final String? reportedUserId;
  final String entityId;
  final String entityType;
  final String reportedName;

  const ReportDialog({
    super.key,
    this.reportedUserId,
    required this.entityId,
    required this.entityType,
    required this.reportedName,
  });

  /// Show the report dialog as a bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    String? reportedUserId,
    required String entityId,
    required String entityType,
    required String reportedName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportDialog(
        reportedUserId: reportedUserId,
        entityId: entityId,
        entityType: entityType,
        reportedName: reportedName,
      ),
    );
  }

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    'Spam',
    'Fraud / Scam',
    'Inappropriate Content',
    'Harassment',
    'False Information',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(moderationRepositoryProvider);
      await repo.reportContent(
        reporterId: user.id,
        reportedUserId: widget.reportedUserId,
        entityId: widget.entityId,
        entityType: widget.entityType,
        reason: _selectedReason!,
        details: _detailsController.text.trim().isNotEmpty
            ? _detailsController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Report "${widget.reportedName}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a reason for your report:',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...List.generate(_reasons.length, (index) {
            final reason = _reasons[index];
            return RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: Colors.red,
            );
          }),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            decoration: InputDecoration(
              hintText: 'Additional details (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedReason == null || _isSubmitting
                  ? null
                  : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }
}
