// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Fondue';

  @override
  String get navSearch => 'ค้นหา';

  @override
  String get navFeed => 'ฟีด';

  @override
  String get navChat => 'แชท';

  @override
  String get navProfile => 'โปรไฟล์';

  @override
  String get mapFabLabel => 'แผนที่';

  @override
  String get createSheetReportPetTitle => 'รายงานสัตว์เลี้ยง';

  @override
  String get createSheetReportPetSubtitle => 'แจ้งพบ / หาสัตว์หาย';

  @override
  String get createSheetNewPostTitle => 'สร้างโพสต์';

  @override
  String get createSheetNewPostSubtitle => 'แชร์เรื่องราว ข่าวสาร ภาพ';

  @override
  String get profileStatsReports => 'รายงาน';

  @override
  String get profileStatsHelped => 'ช่วยเหลือ';

  @override
  String get profileStatsPoints => 'แต้ม';

  @override
  String get profileEdit => 'แก้ไข';

  @override
  String get profileMenuMyPets => 'สัตว์เลี้ยงของฉัน';

  @override
  String get profileMenuMyReports => 'รายงานของฉัน';

  @override
  String get profileMenuPotentialMatches => 'แมตช์ที่เป็นไปได้';

  @override
  String get profileMenuActivity => 'กิจกรรม';

  @override
  String get profileMenuTopDonors => 'อันดับผู้ใจบุญ';

  @override
  String get profileMenuNotifications => 'แจ้งเตือน';

  @override
  String get profileMenuSettings => 'ตั้งค่า';

  @override
  String get profileMenuLanguage => 'ภาษา';

  @override
  String get profileMenuHelp => 'ช่วยเหลือ';

  @override
  String get profileMenuPrivacy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get profileMenuTerms => 'ข้อกำหนดการใช้งาน';

  @override
  String get profileLoginSignup => 'เข้าสู่ระบบ / สมัครสมาชิก';

  @override
  String get profileSignOut => 'ออกจากระบบ';

  @override
  String get profileLanguageDisplayThai => 'ไทย';

  @override
  String get profileLanguageDisplayEnglish => 'English';

  @override
  String get profileBadgesTitle => 'เหรียญรางวัล';

  @override
  String get profileBadgeUnlocked => '✅ ได้รับแล้ว';

  @override
  String get profileBadgeLocked => '🔒 ยังไม่ปลดล็อก';

  @override
  String profilePointsLabel(int points) {
    return '$points แต้ม';
  }

  @override
  String profileNextLevelPrefix(String label) {
    return 'ถัดไป: $label';
  }

  @override
  String get profileMaxLevel => 'สูงสุดแล้ว!';

  @override
  String profileStreakDays(int count) {
    return '🔥 $count วันติด';
  }

  @override
  String get storeTitle => 'ร้านค้า';

  @override
  String get storeSubtitle => 'อาหาร • อุปกรณ์ • ของเล่นสัตว์เลี้ยง';

  @override
  String get settingsTitle => 'ตั้งค่า';

  @override
  String get settingsSectionAccount => 'บัญชีและความปลอดภัย';

  @override
  String get settingsChangePassword => 'เปลี่ยนรหัสผ่าน';

  @override
  String get settingsDeleteAccount => 'ลบบัญชี';

  @override
  String get settingsBlockedUsers => 'ผู้ใช้ที่บล็อก';

  @override
  String get settingsSectionNotifications => 'การแจ้งเตือน';

  @override
  String get settingsPushNotifications => 'การแจ้งเตือนพุช';

  @override
  String get settingsSectionData => 'จัดการข้อมูล';

  @override
  String get settingsClearCache => 'ล้างแคชแอป';

  @override
  String get settingsSectionAbout => 'เกี่ยวกับ';

  @override
  String get settingsVersion => 'เวอร์ชัน';

  @override
  String get settingsTermsOfService => 'ข้อกำหนดการให้บริการ';

  @override
  String get settingsPrivacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get settingsComingSoon => 'เร็วๆ นี้';

  @override
  String get settingsCacheCleared => 'ล้างแคชแล้ว';

  @override
  String get settingsDeleteDialogTitle => 'ลบบัญชี';

  @override
  String get settingsDeleteDialogBody =>
      'คุณแน่ใจหรือไม่ว่าต้องการลบบัญชี การดำเนินการนี้ไม่สามารถย้อนกลับได้ และข้อมูลทั้งหมดของคุณจะสูญหาย';

  @override
  String get settingsCancel => 'ยกเลิก';

  @override
  String get settingsDelete => 'ลบ';

  @override
  String get settingsDeletionRequested => 'ส่งคำขอลบบัญชีแล้ว';

  @override
  String get languageTitle => 'ภาษา';

  @override
  String get languageOptionDevice => 'ตามภาษาอุปกรณ์';

  @override
  String get languageOptionThai => 'ไทย';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get potentialMatchesScreenTitle => 'แมตช์ที่เป็นไปได้ของฉัน';

  @override
  String get potentialMatchesRefreshTooltip => 'รีเฟรช';

  @override
  String get potentialMatchesSearching => 'กำลังค้นหาแมตช์…';

  @override
  String potentialMatchesErrorLine(String message) {
    return 'ข้อผิดพลาด: $message';
  }

  @override
  String get potentialMatchesRetry => 'ลองอีกครั้ง';

  @override
  String get potentialMatchesEmptyTitle => 'ไม่พบแมตช์';

  @override
  String get potentialMatchesEmptyBody =>
      'เรายังไม่พบแมตช์ที่เป็นไปได้สำหรับสัตว์เลี้ยงที่หายของคุณ ลองกลับมาดูอีกครั้งเมื่อมีการแจ้งพบสัตว์ใหม่';

  @override
  String get potentialMatchesCheckAgain => 'ตรวจสอบอีกครั้ง';

  @override
  String get potentialMatchesCardLabel => 'แมตช์ที่เป็นไปได้';

  @override
  String potentialMatchesScorePercent(int score) {
    return 'แมตช์ $score%';
  }

  @override
  String get potentialMatchesYourLostPet => 'สัตว์หายของคุณ';

  @override
  String get potentialMatchesFoundPet => 'สัตว์ที่พบ';

  @override
  String get potentialMatchesViewFoundPet => 'ดูรายละเอียดสัตว์ที่พบ';

  @override
  String get potentialMatchesDismiss => 'ไม่ใช่สัตว์ของฉัน ไม่ต้องแสดงอีก';

  @override
  String get potentialMatchesHideDialogTitle => 'ซ่อนแมตช์นี้?';

  @override
  String get potentialMatchesHideDialogBody =>
      'แมตช์นี้จะถูกซ่อนจากรายการของคุณ คุณยังค้นหาสัตว์ตัวนี้ในฟีดทั่วไปได้';

  @override
  String get potentialMatchesHideMatch => 'ซ่อนแมตช์';

  @override
  String get potentialMatchesHiddenSnack => 'ซ่อนแมตช์แล้ว จะไม่แสดงอีก';

  @override
  String get potentialMatchesHideFailedSnack =>
      'ซ่อนแมตช์ไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get petFilterAll => 'ทั้งหมด';

  @override
  String get petFilterLost => 'หาย';

  @override
  String get petFilterFound => 'พบ';

  @override
  String get petFilterDogs => 'สุนัข';

  @override
  String get petFilterCats => 'แมว';

  @override
  String get petStatusLost => 'หาย';

  @override
  String get petStatusFound => 'พบ';

  @override
  String get petStatusReunited => 'กลับคืน';

  @override
  String get petSexMale => 'ผู้';

  @override
  String get petSexFemale => 'เมีย';

  @override
  String get petSexUnknown => 'ไม่ทราบ';

  @override
  String get mapViewTitle => 'แผนที่สัตว์เลี้ยง';

  @override
  String get mapViewSearchPhotoHint => 'ค้นหาด้วยรูป…';

  @override
  String get mapViewListViewButton => 'มุมมองรายการ';

  @override
  String mapViewErrorLoading(String message) {
    return 'โหลดแผนที่ไม่สำเร็จ: $message';
  }

  @override
  String get mapViewViewDetails => 'ดูรายละเอียด';

  @override
  String mapViewTimeMonthsAgo(int months) {
    return '$months เดือนที่แล้ว';
  }

  @override
  String mapViewTimeDaysAgo(int days) {
    return '$days วันที่แล้ว';
  }

  @override
  String mapViewTimeHoursAgo(int hours) {
    return '$hours ชั่วโมงที่แล้ว';
  }

  @override
  String mapViewTimeMinutesAgo(int minutes) {
    return '$minutes นาทีที่แล้ว';
  }

  @override
  String get petFeedTitle => 'สัตว์ที่พบและหาย';

  @override
  String get petFeedMapTooltip => 'มุมมองแผนที่';

  @override
  String get petFeedMatchDialogTitle => 'พบแมตช์ที่เป็นไปได้!';

  @override
  String petFeedMatchDialogBody(String species, String name) {
    return 'มีคนพบสัตว์ที่คล้ายกับสัตว์$speciesที่หายของคุณชื่อ “$name”!';
  }

  @override
  String get petFeedFoundPetDetails => 'รายละเอียดสัตว์ที่พบ';

  @override
  String petFeedColorLabel(String color) {
    return 'สี: $color';
  }

  @override
  String get petFeedNoDescription => 'ไม่มีคำอธิบาย';

  @override
  String get petFeedDismiss => 'ปิด';

  @override
  String get petFeedViewFoundPet => 'ดูสัตว์ที่พบ';

  @override
  String get petFeedSearch => 'ค้นหา';

  @override
  String get petFeedDefaultPetName => 'สัตว์เลี้ยง';

  @override
  String get petFeedUnknownValue => 'ไม่ทราบ';

  @override
  String get petFeedEmptyTitle => 'ไม่พบสัตว์';

  @override
  String get petFeedEmptySubtitle => 'ลองปรับตัวกรองหรือกลับมาดูอีกครั้ง';

  @override
  String get petFeedErrorTitle => 'เกิดข้อผิดพลาด';

  @override
  String get petDetailShareImageTooltip => 'แชร์เป็นรูปภาพ';

  @override
  String get petDetailArchiveTooltip => 'เก็บถาวร';

  @override
  String get petDetailEditTooltip => 'แก้ไข';

  @override
  String get petDetailReportPost => 'รายงานโพสต์';

  @override
  String get petDetailBlockUser => 'บล็อกผู้ใช้';

  @override
  String get petDetailEditTitle => 'แก้ไขรายละเอียดสัตว์';

  @override
  String get petDetailLabelPetName => 'ชื่อสัตว์';

  @override
  String get petDetailLabelStatus => 'สถานะ';

  @override
  String get petDetailLabelSex => 'เพศ';

  @override
  String get petDetailLabelColor => 'สี';

  @override
  String get petDetailLabelDescription => 'คำอธิบาย';

  @override
  String get petDetailLabelContact => 'ข้อมูลติดต่อ';

  @override
  String get petDetailSave => 'บันทึก';

  @override
  String get petDetailPetUpdatedSnack => 'อัปเดตรายละเอียดแล้ว!';

  @override
  String get petDetailArchiveSheetTitle => 'เก็บโพสต์นี้';

  @override
  String get petDetailArchiveSheetSubtitle => 'เลือกการดำเนินการสำหรับโพสต์นี้';

  @override
  String get petDetailArchiveFoundTitle => 'พบสัตว์แล้ว';

  @override
  String get petDetailArchiveFoundSubtitle =>
      'ทำเครื่องหมายว่ากลับคืนกับเจ้าของ';

  @override
  String get petDetailArchiveDeleteTitle => 'ลบ';

  @override
  String get petDetailArchiveDeleteSubtitle => 'ลบโพสต์นี้ถาวร';

  @override
  String get petDetailMarkFoundTitle => 'พบสัตว์แล้ว!';

  @override
  String get petDetailMarkFoundBody =>
      'ข่าวดี! การทำเครื่องหมายว่ากลับคืนจะเก็บโพสต์นี้ ดำเนินการต่อหรือไม่?';

  @override
  String get petDetailMarkReunitedButton => 'ทำเครื่องหมายว่ากลับคืน';

  @override
  String get petDetailReunitedSnack => 'ทำเครื่องหมายว่ากลับคืนแล้ว!';

  @override
  String get petDetailDeletePostTitle => 'ลบโพสต์';

  @override
  String get petDetailDeletePostBody =>
      'คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้ถาวร การกระทำนี้ไม่สามารถย้อนกลับได้';

  @override
  String get petDetailPostDeletedSnack => 'ลบโพสต์แล้ว';

  @override
  String petDetailPhotoOf(int current, int total) {
    return 'รูปที่ $current จาก $total';
  }

  @override
  String get petDetailCountdownExpired => 'หมดอายุแล้ว';

  @override
  String get petDetailExpiresInLabel => 'หมดอายุใน';

  @override
  String get petDetailReportExpiredTitle => 'รายงานหมดอายุ';

  @override
  String get petDetailReportExpiredBody => 'รายงานนี้ไม่ใช้งานแล้ว';

  @override
  String petDetailDurationDaysHours(int days, int hours) {
    return '$days วัน $hours ชั่วโมง';
  }

  @override
  String petDetailDurationHoursMinutes(int hours, int minutes) {
    return '$hours ชั่วโมง $minutes นาที';
  }

  @override
  String petDetailDurationMinutes(int minutes) {
    return '$minutes นาที';
  }

  @override
  String get petDetailDescriptionHeading => 'คำอธิบาย';

  @override
  String get petDetailNoDescription => 'ไม่มีคำอธิบาย';

  @override
  String get petDetailLastSeenHeading => 'ตำแหน่งที่เห็นล่าสุด';

  @override
  String get petDetailSeeOnMap => 'ดูบนแผนที่';

  @override
  String petDetailPostId(String id) {
    return 'รหัสโพสต์: $id';
  }

  @override
  String get petDetailInfoSpecies => 'ชนิด';

  @override
  String get petDetailInfoSex => 'เพศ';

  @override
  String get petDetailInfoColor => 'สี';

  @override
  String get petDetailYourPostTitle => 'โพสต์ของคุณ';

  @override
  String get petDetailYourPostSubtitle => 'แก้ไขหรือตรวจสอบ';

  @override
  String get petDetailCheckingDatabase => 'กำลังตรวจสอบฐานข้อมูล…';

  @override
  String get petDetailRecheckMatches => 'ตรวจสอบแมตช์ในฐานข้อมูลอีกครั้ง';

  @override
  String get petDetailOwnerOfPost => 'คุณเป็นเจ้าของโพสต์นี้';

  @override
  String get petDetailPostOwnedBy => 'โพสต์โดย';

  @override
  String get petDetailDefaultOwnerName => 'เจ้าของสัตว์';

  @override
  String get petDetailChatNow => 'แชทเลย';

  @override
  String get petDetailContact => 'ติดต่อ';

  @override
  String get petDetailNoNewMatches => 'ยังไม่พบแมตช์ใหม่ในตอนนี้';

  @override
  String petDetailErrorCheckingMatches(String message) {
    return 'ตรวจสอบแมตช์ไม่สำเร็จ: $message';
  }

  @override
  String petDetailMatchResultsTitle(int count) {
    return 'พบ $count แมตช์ที่เป็นไปได้!';
  }

  @override
  String petDetailMatchListTileTitle(String species, int score) {
    return 'พบ$species (แมตช์ $score%)';
  }

  @override
  String get petDetailClose => 'ปิด';

  @override
  String get petDetailChatNoOwner => 'เริ่มแชทไม่ได้: ไม่มีข้อมูลเจ้าของ';

  @override
  String get petDetailChatLoginRequired => 'กรุณาเข้าสู่ระบบเพื่อแชท';

  @override
  String petDetailChatFailed(String message) {
    return 'เริ่มแชทไม่สำเร็จ: $message';
  }

  @override
  String get petDetailCannotCall => 'โทรออกไม่ได้';

  @override
  String get petDetailReportDialogTitle => 'รายงานโพสต์';

  @override
  String get petDetailReportDialogPrompt => 'ทำไมคุณถึงรายงานโพสต์นี้?';

  @override
  String get petDetailReportHint => 'เช่น เนื้อหาไม่เหมาะสม สแปม…';

  @override
  String get petDetailReportSubmit => 'รายงาน';

  @override
  String get petDetailReportLoginRequired => 'กรุณาเข้าสู่ระบบเพื่อรายงาน';

  @override
  String get petDetailReportThanks => 'ส่งรายงานแล้ว ขอบคุณที่ช่วยดูแลชุมชน';

  @override
  String petDetailReportError(String message) {
    return 'ส่งรายงานไม่สำเร็จ: $message';
  }

  @override
  String get petDetailBlockDialogTitle => 'บล็อกผู้ใช้';

  @override
  String get petDetailBlockDialogBody =>
      'คุณแน่ใจหรือไม่ว่าต้องการบล็อกผู้ใช้นี้ คุณจะไม่เห็นโพสต์ของพวกเขาอีก';

  @override
  String get petDetailBlockSubmit => 'บล็อก';

  @override
  String get petDetailBlockLoginRequired => 'กรุณาเข้าสู่ระบบเพื่อบล็อก';

  @override
  String get petDetailUserBlocked => 'บล็อกผู้ใช้แล้ว';

  @override
  String petDetailBlockError(String message) {
    return 'บล็อกไม่สำเร็จ: $message';
  }

  @override
  String petDetailGenericError(String message) {
    return 'ข้อผิดพลาด: $message';
  }
}
