import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/constants.dart';
import 'donation_providers.dart';
import 'latest_donors_strip.dart';
import 'top_donors_screen.dart';

class DonateScreen extends ConsumerStatefulWidget {
  const DonateScreen({super.key});

  @override
  ConsumerState<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends ConsumerState<DonateScreen> {
  final _feedbackController = TextEditingController();
  bool _feedbackSent = false;
  bool _sending = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _openStripeOnWeb() async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/donate');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เปิดเบราว์เซอร์ไม่สำเร็จ', style: GoogleFonts.prompt())),
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    final msg = _feedbackController.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      await http.post(
        Uri.parse('${const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://hadyai-flood.vercel.app')}/api/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: '{"message":"$msg","source":"mobile_donate"}',
      );
    } catch (_) {}
    if (mounted) {
      setState(() {
        _sending = false;
        _feedbackSent = true;
      });
      _feedbackController.clear();
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _feedbackSent = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestAsync = ref.watch(latestDonationsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E1B4B)],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 16, color: Color(0x99FFFFFF)),
                      label: Text('กลับ', style: GoogleFonts.prompt(color: const Color(0x99FFFFFF), fontSize: 14)),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const TopDonorsScreen()),
                        );
                      },
                      icon: const Icon(Icons.emoji_events_outlined, size: 18, color: Color(0xFFFBBF24)),
                      label: Text(
                        'Top Donate',
                        style: GoogleFonts.prompt(color: const Color(0xFFFBBF24), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Text('☕', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFA78BFA)],
                  ).createShader(bounds),
                  child: Text(
                    'ซื้อกาแฟให้ทีมงาน',
                    style: GoogleFonts.prompt(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'เราสร้างแอปนี้เพื่อคนไทยทุกคน 💛\nน้ำใจของคุณช่วยให้เราพัฒนาต่อไปได้ครับ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), height: 1.6),
                ),

                const SizedBox(height: 20),

                latestAsync.when(
                  loading: () => const SizedBox(
                    height: 88,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFFBBF24), strokeWidth: 2)),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (list) => LatestDonorsStrip(donations: list, forLightBackground: false),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openStripeOnWeb,
                    icon: const Icon(Icons.credit_card, color: Color(0xFF6366F1)),
                    label: Text(
                      'เลี้ยงกาแฟด้วยบัตร / Apple Pay (Stripe) — เปิดเว็บ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    _AmountCard(emoji: '☕', amount: '฿30', desc: 'กาแฟรถเข็น'),
                    const SizedBox(width: 10),
                    _AmountCard(emoji: '📦', amount: '฿50', desc: 'Café Amazon'),
                    const SizedBox(width: 10),
                    _AmountCard(emoji: '☕', amount: '฿99', desc: 'Starbucks'),
                  ],
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 8),
                          Text('ฝากข้อความถึงทีมงาน',
                              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFFBBF24))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_feedbackSent) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(
                              children: [
                                const Text('💛', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 8),
                                Text('ขอบคุณสำหรับข้อความครับ!',
                                    style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
                                const SizedBox(height: 4),
                                Text('ทีมงานจะอ่านทุกข้อความ 🙏',
                                    style: GoogleFonts.prompt(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Text('อยากให้เพิ่มฟีเจอร์อะไร? มีข้อเสนอแนะ? หรือแค่อยากส่งกำลังใจ — เขียนถึงเราได้เลยครับ 😊',
                            style: GoogleFonts.prompt(fontSize: 13, color: Colors.white.withValues(alpha: 0.6), height: 1.6)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _feedbackController,
                          maxLines: 3,
                          style: GoogleFonts.prompt(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'เขียนข้อความถึงทีมงาน...',
                            hintStyle: GoogleFonts.prompt(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFFBBF24)),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _sending ? null : _sendFeedback,
                            icon: _sending
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E293B)))
                                : const Icon(Icons.send, size: 14),
                            label: Text(
                              _sending ? 'กำลังส่ง...' : 'ส่งข้อความ',
                              style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFBBF24),
                              foregroundColor: const Color(0xFF1E293B),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text('❤️ ขอบคุณทุกน้ำใจ',
                    style: GoogleFonts.prompt(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
                const SizedBox(height: 4),
                Text('Made with love for Thailand 🇹🇭',
                    style: GoogleFonts.prompt(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String emoji;
  final String amount;
  final String desc;

  const _AmountCard({required this.emoji, required this.amount, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(amount, style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            Text(desc, style: GoogleFonts.prompt(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}
