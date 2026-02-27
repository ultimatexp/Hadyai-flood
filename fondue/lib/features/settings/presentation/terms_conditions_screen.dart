import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildThaiSection(),
            const SizedBox(height: 32),
            const Divider(thickness: 2),
            const SizedBox(height: 32),
            _buildEnglishSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.description, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'FONDUE APPLICATION',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'TERMS AND CONDITIONS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Text(
            'Effective Date: 8 February 2026',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            'Support: mdcusport@gmail.com',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildThaiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ภาษาไทย (TH)', Icons.flag),
        const SizedBox(height: 16),
        _buildSubtitle('ข้อกำหนดและเงื่อนไขการใช้งาน'),
        _buildParagraph('Fondue – แพลตฟอร์มตามหาสัตว์เลี้ยง'),
        _buildParagraph('Fondue เป็นแพลตฟอร์มสำหรับแจ้งสัตว์เลี้ยงสูญหาย และแจ้งพบสัตว์เลี้ยง เพื่อเชื่อมต่อผู้ใช้เข้าด้วยกัน'),
        _buildParagraph('Fondue ไม่รับประกันผลสำเร็จในการตามหาสัตว์เลี้ยง และไม่ตรวจสอบหรือรับรองความเป็นเจ้าของสัตว์'),
        const SizedBox(height: 16),
        _buildSubtitle('หน้าที่ของผู้ใช้:'),
        _buildBulletPoint('ให้ข้อมูลที่ถูกต้องและเป็นความจริง'),
        _buildBulletPoint('ใช้บริการอย่างสุจริตและถูกต้องตามกฎหมาย'),
        _buildBulletPoint('ใช้วิจารณญาณและความระมัดระวังในการติดต่อกับผู้ใช้รายอื่น'),
        const SizedBox(height: 16),
        _buildSubtitle('ห้ามผู้ใช้:'),
        _buildBulletPoint('แอบอ้างหรือปลอมแปลงตัวตน'),
        _buildBulletPoint('โพสต์ข้อมูลเท็จหรือทำให้เข้าใจผิด'),
        _buildBulletPoint('หลอกลวง ฉ้อโกง หรือเรียกร้องเงินโดยมิชอบ'),
        _buildBulletPoint('โพสต์เนื้อหาที่ไม่เหมาะสม ลามกอนาจาร หรือเนื้อหาที่สร้างความเกลียดชัง'),
        _buildBulletPoint('คุกคาม ข่มขู่ หรือกลั่นแกล้งผู้ใช้รายอื่น'),
        const SizedBox(height: 16),
        _buildWarningBox(
          'นโยบายไม่ยอมรับเนื้อหาที่ไม่เหมาะสม',
          'Fondue มีนโยบายไม่ยอมรับเนื้อหาที่ไม่เหมาะสมหรือพฤติกรรมที่ไม่เหมาะสมอย่างเด็ดขาด ผู้ใช้สามารถรายงานเนื้อหาหรือผู้ใช้ที่ไม่เหมาะสมได้ และสามารถบล็อกผู้ใช้ที่มีพฤติกรรมไม่เหมาะสมได้\n\nเนื้อหาที่ถูกรายงานจะได้รับการตรวจสอบภายใน 24 ชั่วโมง ผู้ใช้ที่ฝ่าฝืนอาจถูกระงับหรือลบบัญชีออกจากระบบ',
        ),
        const SizedBox(height: 16),
        _buildWarningBox(
          'ข้อจำกัดความรับผิด',
          'Fondue ไม่เป็นคู่สัญญา และไม่เกี่ยวข้องกับข้อตกลงใด ๆ ระหว่างผู้ใช้ การติดต่อหรือการตกลงใด ๆ ถือเป็นความเสี่ยงและความรับผิดชอบของผู้ใช้เอง\n\nFondue ไม่รับผิดชอบต่อ:\n• การฉ้อโกงหรือการหลอกลวง\n• ความเสียหายทางการเงินหรือทางจิตใจ\n• ข้อพิพาทระหว่างผู้ใช้',
        ),
        const SizedBox(height: 12),
        _buildParagraph('ข้อกำหนดนี้อยู่ภายใต้บังคับแห่งกฎหมายของราชอาณาจักรไทย'),
      ],
    );
  }

  Widget _buildEnglishSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('English (EN)', Icons.language),
        const SizedBox(height: 16),
        _buildSubtitle('Terms and Conditions'),
        _buildParagraph('Fondue – Lost & Found Pets Platform'),
        _buildParagraph('Fondue provides an online platform to report lost and found pets.'),
        _buildParagraph('Fondue does not guarantee successful reunions and does not verify pet ownership or user claims.'),
        const SizedBox(height: 16),
        _buildSubtitle('User responsibilities:'),
        _buildBulletPoint('Provide accurate and truthful information'),
        _buildBulletPoint('Use the service lawfully and responsibly'),
        _buildBulletPoint('Exercise caution when interacting with other users'),
        const SizedBox(height: 16),
        _buildSubtitle('Prohibited conduct includes:'),
        _buildBulletPoint('Impersonation or false representation'),
        _buildBulletPoint('Posting misleading or fraudulent content'),
        _buildBulletPoint('Scams, fraud, or unlawful solicitation of money'),
        _buildBulletPoint('Posting obscene, offensive, or hateful content'),
        _buildBulletPoint('Harassment, bullying, or threatening other users'),
        const SizedBox(height: 16),
        _buildWarningBox(
          'Zero Tolerance for Objectionable Content',
          'Fondue has a zero-tolerance policy for objectionable content and abusive users. Users may report content or block abusive users directly within the app.\n\nReported content is reviewed within 24 hours. Users who violate these terms may have their accounts suspended or permanently removed.',
        ),
        const SizedBox(height: 16),
        _buildWarningBox(
          'Limitation of Liability',
          'Fondue is not a party to any agreement or interaction between users. All interactions occur at the user\'s own risk.\n\nFondue shall not be liable for:\n• Fraud or misrepresentation by users\n• Financial loss or emotional distress\n• Disputes between users',
        ),
        const SizedBox(height: 12),
        _buildParagraph('These Terms are governed by the laws of the Kingdom of Thailand.'),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5)),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
        ],
      ),
    );
  }

  Widget _buildWarningBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5)),
        ],
      ),
    );
  }
}
