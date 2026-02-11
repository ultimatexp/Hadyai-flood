import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
          const Icon(Icons.privacy_tip, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'FONDUE APPLICATION',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'PRIVACY POLICY',
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
        _buildSubtitle('นโยบายความเป็นส่วนตัว'),
        _buildParagraph('Fondue – แพลตฟอร์มตามหาสัตว์เลี้ยงสูญหายและแจ้งพบสัตว์เลี้ยง'),
        _buildParagraph('Fondue ให้ความสำคัญกับการคุ้มครองข้อมูลส่วนบุคคลของผู้ใช้ และปฏิบัติตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA)'),
        const SizedBox(height: 16),
        _buildSubtitle('ข้อมูลที่อาจมีการเก็บรวบรวม:'),
        _buildBulletPoint('ชื่อหรือชื่อที่ใช้แสดงในระบบ'),
        _buildBulletPoint('อีเมลหรือหมายเลขโทรศัพท์'),
        _buildBulletPoint('รูปภาพโปรไฟล์ (ถ้ามี)'),
        _buildBulletPoint('รูปภาพและข้อมูลสัตว์เลี้ยง'),
        _buildBulletPoint('ข้อมูลตำแหน่ง (เฉพาะกรณีที่ผู้ใช้เลือกเปิดเผย)'),
        _buildBulletPoint('ข้อมูลการใช้งานแอปเพื่อความปลอดภัยของระบบ'),
        const SizedBox(height: 16),
        _buildSubtitle('วัตถุประสงค์ในการใช้ข้อมูล:'),
        _buildBulletPoint('เพื่อให้บริการและแสดงประกาศสัตว์เลี้ยงสูญหายหรือแจ้งพบ'),
        _buildBulletPoint('เพื่ออำนวยความสะดวกในการติดต่อระหว่างผู้ใช้'),
        _buildBulletPoint('เพื่อป้องกันการใช้งานในทางที่ผิดและการทุจริต'),
        _buildBulletPoint('เพื่อปฏิบัติตามกฎหมายที่เกี่ยวข้อง'),
        const SizedBox(height: 12),
        _buildParagraph('Fondue จะไม่ขายข้อมูลส่วนบุคคลของผู้ใช้ให้แก่บุคคลที่สาม'),
        const SizedBox(height: 16),
        _buildWarningBox(
          'คำเตือนเกี่ยวกับมิจฉาชีพ',
          'Fondue เป็นแพลตฟอร์มที่เปิดให้ผู้ใช้ติดต่อกันโดยตรง เราไม่สามารถยืนยันตัวตน ความเป็นเจ้าของสัตว์ หรือความถูกต้องของข้อมูลจากผู้ใช้รายอื่นได้\n\nผู้ใช้ไม่ควรโอนเงิน เปิดเผยข้อมูลทางการเงิน หรือรหัสยืนยันใด ๆ ให้แก่บุคคลอื่น\n\nFondue ไม่รับผิดชอบต่อการฉ้อโกง การหลอกลวง หรือความเสียหายใด ๆ ที่เกิดจากการติดต่อหรือการกระทำระหว่างผู้ใช้',
        ),
        const SizedBox(height: 16),
        _buildSubtitle('สิทธิของเจ้าของข้อมูล:'),
        _buildParagraph('ผู้ใช้มีสิทธิขอเข้าถึง แก้ไข หรือลบข้อมูลส่วนบุคคล และสามารถถอนความยินยอมได้ โดยติดต่อที่: mdcusport@gmail.com'),
      ],
    );
  }

  Widget _buildEnglishSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('English (EN)', Icons.language),
        const SizedBox(height: 16),
        _buildSubtitle('Privacy Policy'),
        _buildParagraph('Fondue – Lost & Found Pets Platform'),
        _buildParagraph('Fondue respects user privacy and complies with the Personal Data Protection Act B.E. 2562 (PDPA) of Thailand.'),
        const SizedBox(height: 16),
        _buildSubtitle('Information we may collect:'),
        _buildBulletPoint('Name or display name'),
        _buildBulletPoint('Email address or phone number'),
        _buildBulletPoint('Profile photo (optional)'),
        _buildBulletPoint('Pet photos and pet-related information'),
        _buildBulletPoint('Location data (only if voluntarily shared)'),
        _buildBulletPoint('App usage data for security and analytics'),
        const SizedBox(height: 16),
        _buildSubtitle('Purposes of data use:'),
        _buildBulletPoint('To provide and operate the core app services'),
        _buildBulletPoint('To display lost and found pet listings'),
        _buildBulletPoint('To enable communication between users'),
        _buildBulletPoint('To prevent misuse, abuse, and fraud'),
        _buildBulletPoint('To comply with applicable laws'),
        const SizedBox(height: 12),
        _buildParagraph('Fondue does not sell personal data to third parties.'),
        const SizedBox(height: 16),
        _buildWarningBox(
          'Scam Warning',
          'Fondue is a community-based platform. We do not verify user identity or pet ownership. Users should never send money or share financial or sensitive personal information.\n\nFondue is not responsible for any fraud, loss, or damages arising from user interactions.',
        ),
        const SizedBox(height: 16),
        _buildParagraph('Requests to access, correct, or delete personal data may be submitted to: mdcusport@gmail.com'),
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
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5)),
        ],
      ),
    );
  }
}
