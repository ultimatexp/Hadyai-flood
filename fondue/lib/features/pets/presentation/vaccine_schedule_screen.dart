import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/vaccine_schedule.dart';
import 'vaccine_providers.dart';
import 'pet_profile_providers.dart';

class VaccineScheduleScreen extends ConsumerStatefulWidget {
  final String petProfileId;
  final String petName;
  final String species;

  const VaccineScheduleScreen({
    super.key,
    required this.petProfileId,
    required this.petName,
    required this.species,
  });

  @override
  ConsumerState<VaccineScheduleScreen> createState() => _VaccineScheduleScreenState();
}

class _VaccineScheduleScreenState extends ConsumerState<VaccineScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduleAsync = ref.watch(vaccineScheduleProvider(widget.petProfileId));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : Colors.grey[50],
      body: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (schedule) => _buildContent(context, schedule, isDark),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VaccineScheduleResult schedule, bool isDark) {
    return CustomScrollView(
      slivers: [
        // ═══════════════════════════════
        // HERO HEADER WITH SHIELD SCORE
        // ═══════════════════════════════
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF0F3460),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                      : [const Color(0xFF0F3460), const Color(0xFF533483)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),

                    // Shield Score Gauge
                    _ShieldScoreGauge(
                      score: schedule.shieldScore,
                      size: 110,
                    ),

                    const SizedBox(height: 10),

                    // Title
                    Text(
                      'ตารางวัคซีน ${widget.petName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'มาตรฐานประเทศไทย 🇹🇭',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Quick stats row (outside the app bar to prevent overflow)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatPill('✅', '${schedule.upToDateCount}', 'ครบ', Colors.green),
                _buildStatPill('🟡', '${schedule.dueSoonCount}', 'ใกล้กำหนด', Colors.amber),
                _buildStatPill('🔴', '${schedule.overdueCount}', 'เกินกำหนด', Colors.red),
              ],
            ),
          ),
        ),

        // ═══════════════════════════════
        // URGENCY ALERTS
        // ═══════════════════════════════
        if (schedule.overdueCount > 0)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade500],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${schedule.overdueCount} รายการเกินกำหนด!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'กรุณาพา ${widget.petName} ไปพบสัตวแพทย์โดยเร็ว',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (schedule.dueSoonCount > 0)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${schedule.dueSoonCount} รายการใกล้ถึงกำหนดภายใน 14 วัน',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ═══════════════════════════════
        // TABS: Core / Optional
        // ═══════════════════════════════
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0F3460),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF533483),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🛡️ '),
                      const Text('วัคซีนหลัก'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3460).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${schedule.coreVaccines.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💊 '),
                      const Text('วัคซีนเสริม'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${schedule.optionalVaccines.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ═══════════════════════════════
        // VACCINE LIST
        // ═══════════════════════════════
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVaccineList(schedule.coreVaccines, isDark),
              _buildVaccineList(schedule.optionalVaccines, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaccineList(List<VaccineStatus> vaccines, bool isDark) {
    if (vaccines.isEmpty) {
      return Center(
        child: Text(
          'ไม่มีวัคซีนในหมวดนี้',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    // Sort: overdue first, then dueSoon, then notStarted, then upToDate
    final sorted = List<VaccineStatus>.from(vaccines);
    sorted.sort((a, b) {
      const order = {
        VaccinationState.overdue: 0,
        VaccinationState.dueSoon: 1,
        VaccinationState.notStarted: 2,
        VaccinationState.notApplicable: 3,
        VaccinationState.upToDate: 4,
      };
      return (order[a.state] ?? 5).compareTo(order[b.state] ?? 5);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        return _VaccineCard(
          status: sorted[index],
          isDark: isDark,
          onQuickLog: () => _quickLogVaccine(sorted[index]),
        );
      },
    );
  }

  void _quickLogVaccine(VaccineStatus status) {
    final titleController = TextEditingController(text: status.vaccineInfo.nameTh);
    final descController = TextEditingController();
    DateTime date = DateTime.now();
    DateTime? nextDueDate;

    // Auto-suggest next due date
    if (status.vaccineInfo.annualBoosterDays > 0) {
      nextDueDate = date.add(Duration(days: status.vaccineInfo.annualBoosterDays));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  // Header
                  Row(
                    children: [
                      Text(status.vaccineInfo.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'บันทึกการฉีดวัคซีน',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              status.vaccineInfo.nameEn,
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pre-filled vaccine name
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'ชื่อวัคซีน',
                      prefixIcon: const Icon(Icons.vaccines),
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDark : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'หมายเหตุ (เช่น คลินิก, ยี่ห้อวัคซีน)',
                      prefixIcon: const Icon(Icons.note_alt),
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDark : Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date row
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
                            if (picked != null) {
                              setSheetState(() {
                                date = picked;
                                // Recalculate next due
                                if (status.vaccineInfo.annualBoosterDays > 0) {
                                  nextDueDate = picked.add(Duration(days: status.vaccineInfo.annualBoosterDays));
                                }
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'วันที่ฉีด'),
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
                              initialDate: nextDueDate ?? DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
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

                  const SizedBox(height: 8),
                  if (nextDueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.auto_fix_high, size: 14, color: Colors.purple[300]),
                          const SizedBox(width: 6),
                          Text(
                            'แนะนำ: กระตุ้นทุก ${_boosterLabel(status.vaccineInfo.annualBoosterDays)}',
                            style: TextStyle(fontSize: 12, color: Colors.purple[300]),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Save
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final repo = ref.read(petProfileRepositoryProvider);
                        await repo.addMedicalRecord(
                          petProfileId: widget.petProfileId,
                          recordType: 'vaccination',
                          title: titleController.text.trim(),
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          date: date,
                          nextDueDate: nextDueDate,
                          metadata: {'vaccine_id': status.vaccineInfo.id},
                        );

                        ref.invalidate(medicalRecordsProvider(widget.petProfileId));
                        ref.invalidate(vaccineScheduleProvider(widget.petProfileId));

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('💉 บันทึก ${status.vaccineInfo.nameTh} สำเร็จ!'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('บันทึก'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF533483),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Widget _buildStatPill(String emoji, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            children: [
              Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  String _boosterLabel(int days) {
    if (days <= 0) return 'ไม่ต้องกระตุ้น';
    if (days <= 31) return 'เดือน';
    if (days <= 93) return '3 เดือน';
    return 'ปี';
  }
}

// ═══════════════════════════════════════
// SHIELD SCORE GAUGE
// ═══════════════════════════════════════

class _ShieldScoreGauge extends StatefulWidget {
  final double score;
  final double size;

  const _ShieldScoreGauge({required this.score, this.size = 140});

  @override
  State<_ShieldScoreGauge> createState() => _ShieldScoreGaugeState();
}

class _ShieldScoreGaugeState extends State<_ShieldScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _ShieldScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final percentage = (value * 100).round();

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  progress: value,
                  strokeWidth: 10,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🛡️', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _scoreLabel(value),
                    style: TextStyle(
                      color: _scoreColor(value),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  String _scoreLabel(double score) {
    if (score >= 0.9) return 'ป้องกันดีเยี่ยม!';
    if (score >= 0.7) return 'ป้องกันดี';
    if (score >= 0.4) return 'ควรฉีดเพิ่ม';
    return 'ต้องฉีดด่วน!';
  }

  Color _scoreColor(double score) {
    if (score >= 0.9) return Colors.greenAccent;
    if (score >= 0.7) return Colors.lightGreenAccent;
    if (score >= 0.4) return Colors.amber;
    return Colors.redAccent;
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _GaugePainter({required this.progress, this.strokeWidth = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          _getColor(0.0),
          _getColor(progress),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  Color _getColor(double p) {
    if (p >= 0.8) return Colors.greenAccent;
    if (p >= 0.5) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════
// VACCINE CARD
// ═══════════════════════════════════════

class _VaccineCard extends StatefulWidget {
  final VaccineStatus status;
  final bool isDark;
  final VoidCallback onQuickLog;

  const _VaccineCard({
    required this.status,
    required this.isDark,
    required this.onQuickLog,
  });

  @override
  State<_VaccineCard> createState() => _VaccineCardState();
}

class _VaccineCardState extends State<_VaccineCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.status;
    final stateColor = _stateColor(v.state);
    final isDark = widget.isDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: v.state == VaccinationState.overdue
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5)
            : v.state == VaccinationState.dueSoon
                ? Border.all(color: Colors.amber.withOpacity(0.4))
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon + progress circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: v.progress,
                          strokeWidth: 3,
                          backgroundColor: stateColor.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(stateColor),
                        ),
                      ),
                      Text(v.vaccineInfo.icon, style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.vaccineInfo.nameTh.length > 30
                              ? v.vaccineInfo.nameTh.substring(0, 30) + '...'
                              : v.vaccineInfo.nameTh,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.vaccineInfo.nameEn,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStateBadge(v.state, stateColor),
                            const SizedBox(width: 8),
                            Text(
                              '${v.dosesCompleted}/${v.dosesRequired} เข็ม',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick-log or expand button
                  if (v.state != VaccinationState.notApplicable) ...[
                    IconButton(
                      onPressed: widget.onQuickLog,
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF533483).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Color(0xFF533483), size: 18),
                      ),
                    ),
                  ],

                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    v.vaccineInfo.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Next due
                  if (v.nextDueDate != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: stateColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: stateColor),
                          const SizedBox(width: 8),
                          Text(
                            'ครั้งถัดไป: ${v.nextDueDate!.day}/${v.nextDueDate!.month}/${v.nextDueDate!.year}',
                            style: TextStyle(
                              color: stateColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Dose history
                  if (v.administeredDoses.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'ประวัติการฉีด:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...v.administeredDoses.map((dose) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
                            const SizedBox(width: 8),
                            Text(
                              '${dose.date.day}/${dose.date.month}/${dose.date.year}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                            if (dose.description != null && dose.description!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '— ${dose.description}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStateBadge(VaccinationState state, Color color) {
    String label;
    switch (state) {
      case VaccinationState.upToDate:
        label = '✅ ครบ';
        break;
      case VaccinationState.dueSoon:
        label = '🟡 ใกล้กำหนด';
        break;
      case VaccinationState.overdue:
        label = '🔴 เกินกำหนด';
        break;
      case VaccinationState.notStarted:
        label = '⬜ ยังไม่เริ่ม';
        break;
      case VaccinationState.notApplicable:
        label = '⏳ ยังไม่ถึงอายุ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color _stateColor(VaccinationState state) {
    switch (state) {
      case VaccinationState.upToDate:
        return Colors.green;
      case VaccinationState.dueSoon:
        return Colors.amber.shade700;
      case VaccinationState.overdue:
        return Colors.red;
      case VaccinationState.notStarted:
        return Colors.grey;
      case VaccinationState.notApplicable:
        return Colors.blueGrey;
    }
  }
}
