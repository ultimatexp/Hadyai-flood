import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  static const _promptPayNumber = '0877484066';
  bool _copied = false;

  void _copyNumber() {
    Clipboard.setData(const ClipboardData(text: _promptPayNumber));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('คัดลอกเลข PromptPay แล้ว', style: GoogleFonts.prompt()),
        backgroundColor: const Color(0xFF22C55E),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 16, color: Color(0x99FFFFFF)),
                    label: Text('กลับ', style: GoogleFonts.prompt(color: const Color(0x99FFFFFF), fontSize: 14)),
                  ),
                ),

                const SizedBox(height: 16),

                // Hero
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
                  'เราสร้างแอปนี้เพื่อชาวหาดใหญ่ทุกคน 💛\nน้ำใจของคุณช่วยให้เราพัฒนาต่อไปได้ครับ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(fontSize: 14, color: Colors.white.withOpacity(0.7), height: 1.6),
                ),

                const SizedBox(height: 28),

                // QR Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 60, offset: const Offset(0, 20))],
                  ),
                  child: Column(
                    children: [
                      // Gradient top bar
                      Container(
                        height: 4,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFA78BFA)]),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          children: [
                            Text('สแกนเพื่อบริจาค',
                                style: GoogleFonts.prompt(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                            const SizedBox(height: 4),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                              ).createShader(bounds),
                              child: Text('PromptPay',
                                  style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                            const SizedBox(height: 16),
                            // QR code
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                              ),
                              child: Image.network(
                                'https://promptpay.io/$_promptPayNumber.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                                loadingBuilder: (_, child, progress) {
                                  if (progress == null) return child;
                                  return SizedBox(
                                    width: 200, height: 200,
                                    child: Center(child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                          : null,
                                      color: const Color(0xFF6366F1),
                                    )),
                                  );
                                },
                                errorBuilder: (_, __, ___) => SizedBox(
                                  width: 200, height: 200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.qr_code, size: 80, color: Color(0xFFCBD5E1)),
                                      const SizedBox(height: 8),
                                      Text('PromptPay: $_promptPayNumber',
                                          style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('087-748-4066',
                                    style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B), letterSpacing: 1.5)),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _copyNumber,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _copied ? const Color(0xFF22C55E).withOpacity(0.1) : const Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _copied ? const Color(0xFF22C55E).withOpacity(0.2) : const Color(0xFF6366F1).withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_copied ? Icons.check : Icons.copy, size: 12,
                                            color: _copied ? const Color(0xFF22C55E) : const Color(0xFF6366F1)),
                                        const SizedBox(width: 4),
                                        Text(_copied ? 'แล้ว' : 'คัดลอก',
                                            style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.w600,
                                                color: _copied ? const Color(0xFF22C55E) : const Color(0xFF6366F1))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Amount suggestions
                Row(
                  children: [
                    _AmountCard(emoji: '☕', amount: '฿20', desc: 'กาแฟ 1 แก้ว'),
                    const SizedBox(width: 10),
                    _AmountCard(emoji: '🍜', amount: '฿50', desc: 'ข้าวกลางวัน'),
                    const SizedBox(width: 10),
                    _AmountCard(emoji: '💪', amount: '฿100', desc: 'ค่าเซิร์ฟเวอร์'),
                  ],
                ),

                const SizedBox(height: 24),

                // Why donate
                _MessageCard(
                  icon: Icons.auto_awesome,
                  iconColor: const Color(0xFFFBBF24),
                  title: 'ทำไมต้องบริจาค?',
                  children: [
                    _messageP('🛢️ เช็คน้ำมัน ช่วยให้คุณรู้ว่าปั๊มไหนมีน้ำมัน ไม่ต้องวิ่งหาปั๊มเปล่า'),
                    _messageP('🐾 ตามหาสัตว์เลี้ยง ช่วยให้สัตว์เลี้ยงที่หลุดกลับบ้านได้เร็วขึ้น'),
                    _messageP('🌊 รายงานน้ำท่วม เตือนภัยให้ชาวหาดใหญ่ปลอดภัย'),
                    _messageP('ทุกบาททำให้เราดูแลเซิร์ฟเวอร์ พัฒนาฟีเจอร์ใหม่ และทำแอปนี้ดีขึ้นเรื่อยๆ ครับ 🙏'),
                  ],
                ),

                const SizedBox(height: 16),

                // Thank you
                _MessageCard(
                  icon: Icons.favorite,
                  iconColor: const Color(0xFFF472B6),
                  title: 'ขอบคุณจากใจ',
                  children: [
                    _messageP('แอปนี้สร้างด้วยใจโดยทีมอาสาสมัครที่รักหาดใหญ่ 💛 เราไม่มีโฆษณา ไม่ขายข้อมูล ไม่เก็บค่าสมาชิก'),
                    _messageP('การสนับสนุนของคุณ ไม่ว่าจะเท่าไหร่ ล้วนมีความหมาย — มันบอกว่า "ทีมงานสู้ๆ นะ พวกเราเห็นค่านะ" 😊'),
                  ],
                ),

                const SizedBox(height: 32),

                // Footer
                Text('❤️ ขอบคุณทุกน้ำใจ',
                    style: GoogleFonts.prompt(fontSize: 13, color: Colors.white.withOpacity(0.4))),
                const SizedBox(height: 4),
                Text('Made with love for หาดใหญ่',
                    style: GoogleFonts.prompt(fontSize: 11, color: Colors.white.withOpacity(0.3))),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageP(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: GoogleFonts.prompt(fontSize: 13, color: Colors.white.withOpacity(0.8), height: 1.7)),
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
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(amount, style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            Text(desc, style: GoogleFonts.prompt(fontSize: 10, color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _MessageCard({required this.icon, required this.iconColor, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.w700, color: iconColor)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
