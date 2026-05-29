// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'CapitalMonero';

  @override
  String get username => 'ユーザー名';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get confirmPassword => 'パスワードの確認';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get signIn => 'ログイン';

  @override
  String get signOut => 'ログアウト';

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get recoverAccount => 'アカウントを復元';

  @override
  String get recoveryInstructions =>
      '12 単語のリカバリーフレーズを入力してアカウントへのアクセスを取り戻し、新しいパスワードを設定してください。';

  @override
  String get mnemonicPhrase => 'リカバリーフレーズ';

  @override
  String get twoFactorCode => '二要素認証コード';

  @override
  String get twoFactorSetup => '二要素認証の設定';

  @override
  String get twoFactorSetupIntro =>
      'QR コードをスキャンするか、シークレットを認証アプリにコピーして、6 桁のコードを入力して確認してください。';

  @override
  String get copySecret => 'シークレットをコピー';

  @override
  String get confirm => '確認';

  @override
  String get sessionLockedTitle => 'セッションがロックされました';

  @override
  String get sessionLockedSubtitle => '続行するには PIN または生体認証でロックを解除してください。';

  @override
  String get enterPin => 'PIN を入力';

  @override
  String get unlock => 'ロック解除';

  @override
  String get useBiometrics => '生体認証を使用';

  @override
  String get acceptTerms => '利用規約とプライバシーポリシーに同意します';

  @override
  String get optional => '任意';

  @override
  String get offers => 'オファー';

  @override
  String get wallet => 'ウォレット';

  @override
  String get messages => 'メッセージ';

  @override
  String get search => '検索';

  @override
  String get profile => 'プロフィール';

  @override
  String get buy => '購入';

  @override
  String get sell => '売却';

  @override
  String get buying => '購入中';

  @override
  String get selling => '売却中';

  @override
  String get online => 'オンライン';

  @override
  String get local => 'ローカル';

  @override
  String get createOffer => 'オファーを作成';

  @override
  String get newOffer => '新規オファー';

  @override
  String get editOffer => 'オファーを編集';

  @override
  String get offerType => 'オファーの種類';

  @override
  String get coin => '通貨';

  @override
  String get currency => '法定通貨';

  @override
  String get paymentMethod => '支払い方法';

  @override
  String get priceEquation => '価格式';

  @override
  String get priceEquationHelp =>
      'ライブ価格を追従するには \'market\' を使用してください。例: market*1.02';

  @override
  String get minAmount => '最小金額';

  @override
  String get maxAmount => '最大金額';

  @override
  String get country => '国';

  @override
  String get city => '都市';

  @override
  String get terms => '条件';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get noOffersTitle => 'オファーが見つかりません';

  @override
  String get noOffersHint => '別のフィルターを試すか、独自のオファーを作成してください。';

  @override
  String get openTrade => '取引を開始';

  @override
  String get trade => '取引';

  @override
  String get tradeHistory => '取引履歴';

  @override
  String get tradeChat => '取引チャット';

  @override
  String get dispute => '紛争';

  @override
  String get openDispute => '紛争を起こす';

  @override
  String get fundEscrow => 'エスクローに入金';

  @override
  String get markPaymentSent => '送金済みとしてマーク';

  @override
  String get markPaymentReceived => '入金を確認';

  @override
  String get releaseEscrow => 'エスクローを解放';

  @override
  String get balance => '残高';

  @override
  String get depositAddress => '入金アドレス';

  @override
  String get generateNewAddress => '新しいアドレスを生成';

  @override
  String get withdraw => '出金';

  @override
  String get destinationAddress => '送金先アドレス';

  @override
  String get amount => '金額';

  @override
  String get transactionHistory => '取引履歴';

  @override
  String get noTransactions => '取引はまだありません';

  @override
  String get send => '送信';

  @override
  String get encryptWithPgp => 'PGP で暗号化';

  @override
  String get messagePlaceholder => 'メッセージを入力…';

  @override
  String get notifications => '通知';

  @override
  String get markAllRead => 'すべて既読にする';

  @override
  String get noNotifications => '未読の通知はありません';

  @override
  String get editProfile => 'プロフィールを編集';

  @override
  String get publicProfile => '公開プロフィール';

  @override
  String get feedbackScore => '評価スコア';

  @override
  String get trades => '取引';

  @override
  String get memberSince => '登録日';

  @override
  String get lastSeen => '最終ログイン';

  @override
  String get trustLevel => '信頼レベル';

  @override
  String get languages => '言語';

  @override
  String get savePgpKey => 'PGP 鍵を保存';

  @override
  String get adminPanel => '管理者パネル';

  @override
  String get users => 'ユーザー';

  @override
  String get disputes => '紛争';

  @override
  String get moderation => 'モデレーション';

  @override
  String get statistics => '統計';

  @override
  String get ban => 'BAN';

  @override
  String get warn => '警告';

  @override
  String get verify => '認証';

  @override
  String get search_hint => '通貨・法定通貨・国でオファーを検索';

  @override
  String get filter => 'フィルター';

  @override
  String get sortByPrice => '価格順';

  @override
  String get sortByReputation => '評価順';

  @override
  String get sortByRecency => '新着順';

  @override
  String get loading => '読み込み中…';

  @override
  String get error => 'エラーが発生しました';

  @override
  String get retry => '再試行';
}
