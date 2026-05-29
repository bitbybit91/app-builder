// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'CapitalMonero';

  @override
  String get username => '사용자 이름';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get confirmPassword => '비밀번호 확인';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get signIn => '로그인';

  @override
  String get signOut => '로그아웃';

  @override
  String get createAccount => '계정 만들기';

  @override
  String get forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get recoverAccount => '계정 복구';

  @override
  String get recoveryInstructions =>
      '12단어 복구 문구를 입력하여 계정에 다시 접근하고 새 비밀번호를 설정하세요.';

  @override
  String get mnemonicPhrase => '복구 문구';

  @override
  String get twoFactorCode => '2단계 인증 코드';

  @override
  String get twoFactorSetup => '2단계 인증 설정';

  @override
  String get twoFactorSetupIntro =>
      'QR 코드를 스캔하거나 비밀 키를 인증 앱에 복사한 후 6자리 코드를 입력하여 확인하세요.';

  @override
  String get copySecret => '비밀 키 복사';

  @override
  String get confirm => '확인';

  @override
  String get sessionLockedTitle => '세션이 잠겼습니다';

  @override
  String get sessionLockedSubtitle => 'PIN 또는 생체 인증으로 잠금을 해제하여 계속하세요.';

  @override
  String get enterPin => 'PIN 입력';

  @override
  String get unlock => '잠금 해제';

  @override
  String get useBiometrics => '생체 인증 사용';

  @override
  String get acceptTerms => '이용약관 및 개인정보 처리방침에 동의합니다';

  @override
  String get optional => '선택 사항';

  @override
  String get offers => '오퍼';

  @override
  String get wallet => '지갑';

  @override
  String get messages => '메시지';

  @override
  String get search => '검색';

  @override
  String get profile => '프로필';

  @override
  String get buy => '구매';

  @override
  String get sell => '판매';

  @override
  String get buying => '구매 중';

  @override
  String get selling => '판매 중';

  @override
  String get online => '온라인';

  @override
  String get local => '로컬';

  @override
  String get createOffer => '오퍼 생성';

  @override
  String get newOffer => '새 오퍼';

  @override
  String get editOffer => '오퍼 편집';

  @override
  String get offerType => '오퍼 유형';

  @override
  String get coin => '코인';

  @override
  String get currency => '통화';

  @override
  String get paymentMethod => '결제 방법';

  @override
  String get priceEquation => '가격 식';

  @override
  String get priceEquationHelp =>
      '실시간 가격을 추적하려면 \'market\'을 사용하세요. 예: market*1.02';

  @override
  String get minAmount => '최소 금액';

  @override
  String get maxAmount => '최대 금액';

  @override
  String get country => '국가';

  @override
  String get city => '도시';

  @override
  String get terms => '약관';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get noOffersTitle => '오퍼를 찾을 수 없습니다';

  @override
  String get noOffersHint => '다른 필터를 시도하거나 자신의 오퍼를 만들어 보세요.';

  @override
  String get openTrade => '거래 시작';

  @override
  String get trade => '거래';

  @override
  String get tradeHistory => '거래 내역';

  @override
  String get tradeChat => '거래 채팅';

  @override
  String get dispute => '분쟁';

  @override
  String get openDispute => '분쟁 제기';

  @override
  String get fundEscrow => '에스크로 입금';

  @override
  String get markPaymentSent => '결제 완료 표시';

  @override
  String get markPaymentReceived => '결제 수신 확인';

  @override
  String get releaseEscrow => '에스크로 해제';

  @override
  String get balance => '잔액';

  @override
  String get depositAddress => '입금 주소';

  @override
  String get generateNewAddress => '새 주소 생성';

  @override
  String get withdraw => '출금';

  @override
  String get destinationAddress => '받는 주소';

  @override
  String get amount => '금액';

  @override
  String get transactionHistory => '거래 내역';

  @override
  String get noTransactions => '아직 거래가 없습니다';

  @override
  String get send => '전송';

  @override
  String get encryptWithPgp => 'PGP로 암호화';

  @override
  String get messagePlaceholder => '메시지를 입력하세요…';

  @override
  String get notifications => '알림';

  @override
  String get markAllRead => '모두 읽음 표시';

  @override
  String get noNotifications => '모든 알림을 확인했습니다';

  @override
  String get editProfile => '프로필 편집';

  @override
  String get publicProfile => '공개 프로필';

  @override
  String get feedbackScore => '피드백 점수';

  @override
  String get trades => '거래';

  @override
  String get memberSince => '가입일';

  @override
  String get lastSeen => '마지막 접속';

  @override
  String get trustLevel => '신뢰 등급';

  @override
  String get languages => '언어';

  @override
  String get savePgpKey => 'PGP 키 저장';

  @override
  String get adminPanel => '관리자 패널';

  @override
  String get users => '사용자';

  @override
  String get disputes => '분쟁';

  @override
  String get moderation => '검토';

  @override
  String get statistics => '통계';

  @override
  String get ban => '차단';

  @override
  String get warn => '경고';

  @override
  String get verify => '인증';

  @override
  String get search_hint => '코인, 통화 또는 국가로 오퍼 검색';

  @override
  String get filter => '필터';

  @override
  String get sortByPrice => '가격순 정렬';

  @override
  String get sortByReputation => '평판순 정렬';

  @override
  String get sortByRecency => '최신순 정렬';

  @override
  String get loading => '로딩 중…';

  @override
  String get error => '문제가 발생했습니다';

  @override
  String get retry => '다시 시도';
}
