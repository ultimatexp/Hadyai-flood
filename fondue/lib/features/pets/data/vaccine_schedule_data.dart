/// Thailand standard vaccine schedules for dogs and cats.
/// Based on guidelines from the Thai Veterinary Medical Association (สมาคมสัตวแพทย์ผู้ประกอบการบำบัดโรคสัตว์แห่งประเทศไทย)
/// and Department of Livestock Development (กรมปศุสัตว์).

class VaccineInfo {
  final String id;
  final String nameEn;
  final String nameTh;
  final String species; // 'Dog' or 'Cat'
  final bool isCore;
  final int initialAgeWeeks;
  final int? boosterWeeks; // weeks after initial dose for 2nd/3rd dose
  final int annualBoosterDays; // days between annual boosters (365 or 0 if one-time)
  final int doses; // total primary series doses
  final String description;
  final String icon;

  const VaccineInfo({
    required this.id,
    required this.nameEn,
    required this.nameTh,
    required this.species,
    required this.isCore,
    required this.initialAgeWeeks,
    this.boosterWeeks,
    this.annualBoosterDays = 365,
    this.doses = 1,
    required this.description,
    this.icon = '💉',
  });
}

/// Thailand vaccine schedules
/// Reference: กรมปศุสัตว์ + Thai Veterinary Medical Association
const List<VaccineInfo> thailandVaccineSchedules = [
  // ═══════════════════════════════════════
  // DOG VACCINES (สุนัข)
  // ═══════════════════════════════════════

  // Core vaccines (วัคซีนหลัก)
  VaccineInfo(
    id: 'dog_dhppl',
    nameEn: 'DHPPL (5-in-1)',
    nameTh: 'รวม 5 โรค (ไข้หัดสุนัข, ลำไส้อักเสบ, ตับอักเสบ, พาราอินฟลูเอนซา, เลปโตสไปโรซิส)',
    species: 'Dog',
    isCore: true,
    initialAgeWeeks: 6,
    boosterWeeks: 4,
    annualBoosterDays: 365,
    doses: 3,
    description: 'วัคซีนหลักป้องกัน 5 โรคร้ายในสุนัข ฉีดเข็มแรกอายุ 6 สัปดาห์ กระตุ้นทุก 3-4 สัปดาห์ จำนวน 3 เข็ม แล้วกระตุ้นปีละครั้ง',
    icon: '🛡️',
  ),
  VaccineInfo(
    id: 'dog_rabies',
    nameEn: 'Rabies',
    nameTh: 'พิษสุนัขบ้า',
    species: 'Dog',
    isCore: true,
    initialAgeWeeks: 12,
    annualBoosterDays: 365,
    doses: 1,
    description: 'บังคับตามกฎหมาย พ.ร.บ.โรคพิษสุนัขบ้า พ.ศ. 2535 ฉีดเข็มแรกอายุ 3 เดือนขึ้นไป กระตุ้นปีละครั้ง',
    icon: '⚖️',
  ),

  // Non-core vaccines (วัคซีนเสริม)
  VaccineInfo(
    id: 'dog_kennel_cough',
    nameEn: 'Kennel Cough (Bordetella)',
    nameTh: 'ไอสุนัข (บอร์เดเทลลา)',
    species: 'Dog',
    isCore: false,
    initialAgeWeeks: 8,
    annualBoosterDays: 365,
    doses: 2,
    boosterWeeks: 4,
    description: 'แนะนำสำหรับสุนัขที่เข้าสังคมบ่อย เช่น สนามสุนัข โรงแรมสุนัข ร้านตัดขน',
    icon: '🫁',
  ),
  VaccineInfo(
    id: 'dog_corona',
    nameEn: 'Coronavirus (CCV)',
    nameTh: 'โคโรนาไวรัส',
    species: 'Dog',
    isCore: false,
    initialAgeWeeks: 6,
    boosterWeeks: 3,
    annualBoosterDays: 365,
    doses: 2,
    description: 'ป้องกันโรคลำไส้อักเสบจากโคโรนาไวรัส พบบ่อยในลูกสุนัข',
    icon: '🦠',
  ),
  VaccineInfo(
    id: 'dog_leptospirosis',
    nameEn: 'Leptospirosis',
    nameTh: 'เลปโตสไปโรซิส (โรคฉี่หนู)',
    species: 'Dog',
    isCore: false,
    initialAgeWeeks: 12,
    boosterWeeks: 4,
    annualBoosterDays: 365,
    doses: 2,
    description: 'สำคัญมากในไทย โดยเฉพาะช่วงน้ำท่วมหรือพื้นที่ชื้นแฉะ ป้องกันโรคฉี่หนูที่ติดต่อจากสัตว์สู่คน',
    icon: '🐀',
  ),
  VaccineInfo(
    id: 'dog_heartworm',
    nameEn: 'Heartworm Prevention',
    nameTh: 'ป้องกันพยาธิหัวใจ',
    species: 'Dog',
    isCore: false,
    initialAgeWeeks: 8,
    annualBoosterDays: 30, // monthly
    doses: 1,
    description: 'ให้ยาป้องกันทุกเดือน พบมากในภาคใต้และพื้นที่ชื้นของไทย',
    icon: '❤️',
  ),
  VaccineInfo(
    id: 'dog_tick_flea',
    nameEn: 'Tick & Flea Prevention',
    nameTh: 'ป้องกันเห็บหมัด',
    species: 'Dog',
    isCore: false,
    initialAgeWeeks: 8,
    annualBoosterDays: 30, // monthly
    doses: 1,
    description: 'สำคัญมากในภูมิอากาศร้อนชื้นของไทย ป้องกันโรคจากเห็บ เช่น บาบีเซีย เออร์ลิเชีย',
    icon: '🪲',
  ),
  VaccineInfo(
    id: 'dog_deworming',
    nameEn: 'Deworming',
    nameTh: 'ถ่ายพยาธิ',
    species: 'Dog',
    isCore: true,
    initialAgeWeeks: 2,
    annualBoosterDays: 90, // every 3 months
    doses: 1,
    description: 'ถ่ายพยาธิทุก 3 เดือน เริ่มตั้งแต่อายุ 2 สัปดาห์',
    icon: '💊',
  ),

  // ═══════════════════════════════════════
  // CAT VACCINES (แมว)
  // ═══════════════════════════════════════

  // Core vaccines (วัคซีนหลัก)
  VaccineInfo(
    id: 'cat_fvrcp',
    nameEn: 'FVRCP (3-in-1)',
    nameTh: 'รวม 3 โรค (ไข้หวัดแมว, คาลิซีไวรัส, แพนลิวโคพีเนีย)',
    species: 'Cat',
    isCore: true,
    initialAgeWeeks: 6,
    boosterWeeks: 4,
    annualBoosterDays: 365,
    doses: 3,
    description: 'วัคซีนหลักสำหรับแมว ฉีดเข็มแรกอายุ 6-8 สัปดาห์ กระตุ้นทุก 3-4 สัปดาห์ จำนวน 3 เข็ม แล้วกระตุ้นปีละครั้ง',
    icon: '🛡️',
  ),
  VaccineInfo(
    id: 'cat_rabies',
    nameEn: 'Rabies',
    nameTh: 'พิษสุนัขบ้า',
    species: 'Cat',
    isCore: true,
    initialAgeWeeks: 12,
    annualBoosterDays: 365,
    doses: 1,
    description: 'บังคับตามกฎหมาย ฉีดเข็มแรกอายุ 3 เดือน กระตุ้นปีละครั้ง',
    icon: '⚖️',
  ),

  // Non-core vaccines (วัคซีนเสริม)
  VaccineInfo(
    id: 'cat_felv',
    nameEn: 'FeLV (Feline Leukemia)',
    nameTh: 'มะเร็งเม็ดเลือดขาว (FeLV)',
    species: 'Cat',
    isCore: false,
    initialAgeWeeks: 8,
    boosterWeeks: 4,
    annualBoosterDays: 365,
    doses: 2,
    description: 'แนะนำสำหรับแมวที่ออกนอกบ้านหรืออยู่รวมกับแมวอื่น ควรตรวจ FeLV ก่อนฉีด',
    icon: '🔬',
  ),
  VaccineInfo(
    id: 'cat_fiv',
    nameEn: 'FIV (Feline Immunodeficiency)',
    nameTh: 'ภูมิคุ้มกันบกพร่อง (FIV)',
    species: 'Cat',
    isCore: false,
    initialAgeWeeks: 8,
    boosterWeeks: 3,
    annualBoosterDays: 365,
    doses: 3,
    description: 'พบบ่อยในแมวจรในไทย แนะนำสำหรับแมวที่ออกนอกบ้าน',
    icon: '🧬',
  ),
  VaccineInfo(
    id: 'cat_fip',
    nameEn: 'FIP (Feline Infectious Peritonitis)',
    nameTh: 'เยื่อบุช่องท้องอักเสบ (FIP)',
    species: 'Cat',
    isCore: false,
    initialAgeWeeks: 16,
    annualBoosterDays: 365,
    doses: 2,
    boosterWeeks: 3,
    description: 'วัคซีนชนิดหยอดจมูก พิจารณาสำหรับแมวที่อยู่รวมกันจำนวนมาก',
    icon: '💧',
  ),
  VaccineInfo(
    id: 'cat_deworming',
    nameEn: 'Deworming',
    nameTh: 'ถ่ายพยาธิ',
    species: 'Cat',
    isCore: true,
    initialAgeWeeks: 3,
    annualBoosterDays: 90, // every 3 months
    doses: 1,
    description: 'ถ่ายพยาธิทุก 3 เดือน เริ่มตั้งแต่อายุ 3 สัปดาห์',
    icon: '💊',
  ),
  VaccineInfo(
    id: 'cat_tick_flea',
    nameEn: 'Tick & Flea Prevention',
    nameTh: 'ป้องกันเห็บหมัด',
    species: 'Cat',
    isCore: false,
    initialAgeWeeks: 8,
    annualBoosterDays: 30,
    doses: 1,
    description: 'หยดยากันเห็บหมัดทุกเดือน สำคัญในอากาศร้อนชื้นของไทย',
    icon: '🪲',
  ),
];

/// Get vaccines for a specific species
List<VaccineInfo> getVaccinesForSpecies(String species) {
  return thailandVaccineSchedules.where((v) => v.species == species).toList();
}

/// Get core vaccines only
List<VaccineInfo> getCoreVaccines(String species) {
  return thailandVaccineSchedules.where((v) => v.species == species && v.isCore).toList();
}

/// Get non-core (optional) vaccines only
List<VaccineInfo> getOptionalVaccines(String species) {
  return thailandVaccineSchedules.where((v) => v.species == species && !v.isCore).toList();
}
