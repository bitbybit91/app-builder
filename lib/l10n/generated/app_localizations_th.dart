// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'CapitalMonero';

  @override
  String get username => 'ชื่อผู้ใช้';

  @override
  String get email => 'อีเมล';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get confirmPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get newPassword => 'รหัสผ่านใหม่';

  @override
  String get signIn => 'เข้าสู่ระบบ';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get createAccount => 'สร้างบัญชี';

  @override
  String get forgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get recoverAccount => 'กู้คืนบัญชี';

  @override
  String get recoveryInstructions =>
      'ป้อนวลีกู้คืน 12 คำเพื่อเข้าถึงบัญชีและตั้งรหัสผ่านใหม่';

  @override
  String get mnemonicPhrase => 'วลีกู้คืน';

  @override
  String get twoFactorCode => 'รหัสยืนยันสองชั้น';

  @override
  String get twoFactorSetup => 'ตั้งค่าการยืนยันสองชั้น';

  @override
  String get twoFactorSetupIntro =>
      'สแกน QR หรือคัดลอกรหัสลับลงในแอปยืนยันตัวตน จากนั้นป้อนรหัส 6 หลักเพื่อยืนยัน';

  @override
  String get copySecret => 'คัดลอกรหัสลับ';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get sessionLockedTitle => 'เซสชันถูกล็อก';

  @override
  String get sessionLockedSubtitle =>
      'ปลดล็อกด้วย PIN หรือไบโอเมตริกซ์เพื่อดำเนินการต่อ';

  @override
  String get enterPin => 'ป้อน PIN';

  @override
  String get unlock => 'ปลดล็อก';

  @override
  String get useBiometrics => 'ใช้ไบโอเมตริกซ์';

  @override
  String get acceptTerms => 'ฉันยอมรับข้อกำหนดและนโยบายความเป็นส่วนตัว';

  @override
  String get optional => 'ตัวเลือก';

  @override
  String get offers => 'ข้อเสนอ';

  @override
  String get wallet => 'กระเป๋าเงิน';

  @override
  String get messages => 'ข้อความ';

  @override
  String get search => 'ค้นหา';

  @override
  String get profile => 'โปรไฟล์';

  @override
  String get buy => 'ซื้อ';

  @override
  String get sell => 'ขาย';

  @override
  String get buying => 'กำลังซื้อ';

  @override
  String get selling => 'กำลังขาย';

  @override
  String get online => 'ออนไลน์';

  @override
  String get local => 'ในพื้นที่';

  @override
  String get createOffer => 'สร้างข้อเสนอ';

  @override
  String get newOffer => 'ข้อเสนอใหม่';

  @override
  String get editOffer => 'แก้ไขข้อเสนอ';

  @override
  String get offerType => 'ประเภทข้อเสนอ';

  @override
  String get coin => 'เหรียญ';

  @override
  String get currency => 'สกุลเงิน';

  @override
  String get paymentMethod => 'วิธีชำระเงิน';

  @override
  String get priceEquation => 'สูตรราคา';

  @override
  String get priceEquationHelp =>
      'ใช้ \'market\' เพื่อติดตามราคาตลาด ตัวอย่าง: market*1.02';

  @override
  String get minAmount => 'จำนวนขั้นต่ำ';

  @override
  String get maxAmount => 'จำนวนสูงสุด';

  @override
  String get country => 'ประเทศ';

  @override
  String get city => 'เมือง';

  @override
  String get terms => 'เงื่อนไข';

  @override
  String get save => 'บันทึก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get noOffersTitle => 'ไม่พบข้อเสนอ';

  @override
  String get noOffersHint => 'ลองตัวกรองอื่นหรือสร้างข้อเสนอของคุณเอง';

  @override
  String get openTrade => 'เปิดการค้า';

  @override
  String get trade => 'การค้า';

  @override
  String get tradeHistory => 'ประวัติการค้า';

  @override
  String get tradeChat => 'แชทการค้า';

  @override
  String get dispute => 'ข้อพิพาท';

  @override
  String get openDispute => 'เปิดข้อพิพาท';

  @override
  String get fundEscrow => 'ฝากเงินเข้า escrow';

  @override
  String get markPaymentSent => 'ทำเครื่องหมายว่าโอนแล้ว';

  @override
  String get markPaymentReceived => 'ยืนยันรับเงิน';

  @override
  String get releaseEscrow => 'ปล่อย escrow';

  @override
  String get balance => 'ยอดเงินคงเหลือ';

  @override
  String get depositAddress => 'ที่อยู่สำหรับฝาก';

  @override
  String get generateNewAddress => 'สร้างที่อยู่ใหม่';

  @override
  String get withdraw => 'ถอน';

  @override
  String get destinationAddress => 'ที่อยู่ปลายทาง';

  @override
  String get amount => 'จำนวน';

  @override
  String get transactionHistory => 'ประวัติธุรกรรม';

  @override
  String get noTransactions => 'ยังไม่มีธุรกรรม';

  @override
  String get send => 'ส่ง';

  @override
  String get encryptWithPgp => 'เข้ารหัสด้วย PGP';

  @override
  String get messagePlaceholder => 'พิมพ์ข้อความ…';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get markAllRead => 'ทำเครื่องหมายอ่านทั้งหมด';

  @override
  String get noNotifications => 'คุณอ่านทุกรายการแล้ว';

  @override
  String get editProfile => 'แก้ไขโปรไฟล์';

  @override
  String get publicProfile => 'โปรไฟล์สาธารณะ';

  @override
  String get feedbackScore => 'คะแนนรีวิว';

  @override
  String get trades => 'การค้า';

  @override
  String get memberSince => 'สมาชิกตั้งแต่';

  @override
  String get lastSeen => 'เห็นล่าสุด';

  @override
  String get trustLevel => 'ระดับความน่าเชื่อถือ';

  @override
  String get languages => 'ภาษา';

  @override
  String get savePgpKey => 'บันทึกคีย์ PGP';

  @override
  String get adminPanel => 'แผงผู้ดูแลระบบ';

  @override
  String get users => 'ผู้ใช้';

  @override
  String get disputes => 'ข้อพิพาท';

  @override
  String get moderation => 'การตรวจสอบ';

  @override
  String get statistics => 'สถิติ';

  @override
  String get ban => 'แบน';

  @override
  String get warn => 'เตือน';

  @override
  String get verify => 'ยืนยัน';

  @override
  String get search_hint => 'ค้นหาข้อเสนอตามเหรียญ สกุลเงิน หรือประเทศ';

  @override
  String get filter => 'ตัวกรอง';

  @override
  String get sortByPrice => 'เรียงตามราคา';

  @override
  String get sortByReputation => 'เรียงตามชื่อเสียง';

  @override
  String get sortByRecency => 'เรียงตามใหม่ล่าสุด';

  @override
  String get loading => 'กำลังโหลด…';

  @override
  String get error => 'เกิดข้อผิดพลาด';

  @override
  String get retry => 'ลองอีกครั้ง';
}
