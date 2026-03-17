import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/medical_record.dart';
import 'pet_profile_providers.dart';
import 'vaccine_schedule_screen.dart';
import 'vaccine_providers.dart';

class PetMedicalScreen extends ConsumerStatefulWidget {
  final String petProfileId;
  final String petName;
  final String species;

  const PetMedicalScreen({
    super.key,
    required this.petProfileId,
    required this.petName,
    this.species = 'Dog',
  });

  @override
  ConsumerState<PetMedicalScreen> createState() => _PetMedicalScreenState();
}

class _PetMedicalScreenState extends ConsumerState<PetMedicalScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        title: Text('สุขภาพ ${widget.petName}'),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecordSheet(context, isDark),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มบันทึก'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final recordsAsync = ref.watch(medicalRecordsProvider(widget.petProfileId));

          return recordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (records) {
              if (records.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.medical_services_outlined, size: 48, color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีบันทึกสุขภาพ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เริ่มบันทึกวัคซีน การตรวจสุขภาพ\nและยาของ ${widget.petName} ที่นี่',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              // Group by type
              final grouped = <String, List<MedicalRecord>>{};
              for (final r in records) {
                grouped.putIfAbsent(r.recordType, () => []).add(r);
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Vaccine schedule hero button
                  _buildVaccineHeroButton(isDark),
                  const SizedBox(height: 12),

                  // Summary card
                  _buildSummaryCard(records, isDark),
                  const SizedBox(height: 16),

                  // Records by type
                  ...grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _recordTypeIcon(entry.key),
                                size: 20,
                                color: _recordTypeColor(entry.key),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _recordTypeLabel(entry.key),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _recordTypeColor(entry.key).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${entry.value.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _recordTypeColor(entry.key),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...entry.value.map((record) => _buildRecordCard(record, isDark)),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),

                  const SizedBox(height: 80),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<MedicalRecord> records, bool isDark) {
    final vaccinations = records.where((r) => r.recordType == 'vaccination').length;
    final vetVisits = records.where((r) => r.recordType == 'vet_visit').length;
    final overdue = records.where((r) => r.isOverdue).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('💉', '$vaccinations', 'วัคซีน'),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem('🏥', '$vetVisits', 'ตรวจสุขภาพ'),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem(
            overdue > 0 ? '⚠️' : '✅',
            overdue > 0 ? '$overdue' : 'OK',
            overdue > 0 ? 'เกินกำหนด' : 'สถานะ',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecordCard(MedicalRecord record, bool isDark) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ลบบันทึก?'),
            content: Text('ต้องการลบ "${record.title}" หรือไม่?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ลบ', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        final repo = ref.read(petProfileRepositoryProvider);
        await repo.deleteMedicalRecord(record.id);
        ref.invalidate(medicalRecordsProvider(widget.petProfileId));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: record.isOverdue
              ? Border.all(color: Colors.red.withOpacity(0.4))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _recordTypeColor(record.recordType).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _recordTypeIcon(record.recordType),
                color: _recordTypeColor(record.recordType),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (record.description != null && record.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        record.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${record.date.day}/${record.date.month}/${record.date.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      if (record.nextDueDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          record.isOverdue ? Icons.error_outline : Icons.schedule,
                          size: 12,
                          color: record.isOverdue ? Colors.red : Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ถัดไป: ${record.nextDueDate!.day}/${record.nextDueDate!.month}/${record.nextDueDate!.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: record.isOverdue ? Colors.red : Colors.amber[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Add Record Bottom Sheet ──────────────────────────────────
  void _showAddRecordSheet(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String recordType = 'vaccination';
    DateTime date = DateTime.now();
    DateTime? nextDueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'เพิ่มบันทึกสุขภาพ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Record type selector
                  const Text('ประเภท', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['vaccination', 'vet_visit', 'medication', 'weight_log', 'note']
                        .map((type) {
                      final selected = recordType == type;
                      return ChoiceChip(
                        label: Text(_recordTypeLabel(type)),
                        selected: selected,
                        selectedColor: _recordTypeColor(type).withOpacity(0.2),
                        avatar: Icon(_recordTypeIcon(type), size: 18, color: _recordTypeColor(type)),
                        onSelected: (_) => setSheetState(() => recordType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'หัวข้อ *',
                      hintText: 'เช่น วัคซีนพิษสุนัขบ้า',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียด',
                      hintText: 'หมายเหตุเพิ่มเติม (ถ้ามี)',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date & Next due date
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: date,
                              firstDate: DateTime(2010),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setSheetState(() => date = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'วันที่'),
                            child: Text('${date.day}/${date.month}/${date.year}'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setSheetState(() => nextDueDate = picked);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'ครั้งถัดไป'),
                            child: Text(
                              nextDueDate != null
                                  ? '${nextDueDate!.day}/${nextDueDate!.month}/${nextDueDate!.year}'
                                  : '-',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('กรุณาใส่หัวข้อ')),
                          );
                          return;
                        }

                        final repo = ref.read(petProfileRepositoryProvider);
                        await repo.addMedicalRecord(
                          petProfileId: widget.petProfileId,
                          recordType: recordType,
                          title: titleController.text.trim(),
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          date: date,
                          nextDueDate: nextDueDate,
                        );

                        ref.invalidate(medicalRecordsProvider(widget.petProfileId));

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ บันทึกสำเร็จ!'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('บันทึก'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Vaccine Hero Button ──────────────────────────────────────
  Widget _buildVaccineHeroButton(bool isDark) {
    final scheduleAsync = ref.watch(vaccineScheduleProvider(widget.petProfileId));

    return scheduleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schedule) {
        final percentage = (schedule.shieldScore * 100).round();

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VaccineScheduleScreen(
                  petProfileId: widget.petProfileId,
                  petName: widget.petName,
                  species: widget.species,
                ),
              ),
            ).then((_) {
              ref.invalidate(medicalRecordsProvider(widget.petProfileId));
              ref.invalidate(vaccineScheduleProvider(widget.petProfileId));
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFF0F3460), const Color(0xFF533483)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF533483).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Shield
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: schedule.shieldScore,
                        strokeWidth: 3.5,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(
                          schedule.shieldScore >= 0.8 ? Colors.green : (schedule.shieldScore >= 0.5 ? Colors.amber : Colors.red),
                        ),
                      ),
                      const Text('🛡️', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ตารางวัคซีนมาตรฐานไทย 🇹🇭',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ป้องกัน $percentage% • ${schedule.overdueCount > 0 ? "${schedule.overdueCount} รายการเกินกำหนด" : "ดูและจัดการวัคซีน"}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.6)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  IconData _recordTypeIcon(String type) {
    switch (type) {
      case 'vaccination': return Icons.vaccines;
      case 'vet_visit': return Icons.local_hospital;
      case 'medication': return Icons.medication;
      case 'weight_log': return Icons.monitor_weight;
      case 'note': return Icons.note_alt;
      default: return Icons.description;
    }
  }

  Color _recordTypeColor(String type) {
    switch (type) {
      case 'vaccination': return Colors.blue;
      case 'vet_visit': return Colors.green;
      case 'medication': return Colors.purple;
      case 'weight_log': return Colors.teal;
      case 'note': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _recordTypeLabel(String type) {
    switch (type) {
      case 'vaccination': return 'วัคซีน';
      case 'vet_visit': return 'ตรวจสุขภาพ';
      case 'medication': return 'ยา';
      case 'weight_log': return 'น้ำหนัก';
      case 'note': return 'หมายเหตุ';
      default: return type;
    }
  }
}
