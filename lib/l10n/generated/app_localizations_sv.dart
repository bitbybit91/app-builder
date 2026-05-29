// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appName => 'CapitalMonero';

  @override
  String get username => 'Användarnamn';

  @override
  String get email => 'E-post';

  @override
  String get password => 'Lösenord';

  @override
  String get confirmPassword => 'Bekräfta lösenord';

  @override
  String get newPassword => 'Nytt lösenord';

  @override
  String get signIn => 'Logga in';

  @override
  String get signOut => 'Logga ut';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get forgotPassword => 'Glömt lösenord?';

  @override
  String get recoverAccount => 'Återskapa konto';

  @override
  String get recoveryInstructions =>
      'Ange din 12-ords återställningsfras för att återfå tillgång till kontot och sätta ett nytt lösenord.';

  @override
  String get mnemonicPhrase => 'Återställningsfras';

  @override
  String get twoFactorCode => 'Tvåfaktorskod';

  @override
  String get twoFactorSetup => 'Aktivera tvåfaktorsautentisering';

  @override
  String get twoFactorSetupIntro =>
      'Skanna QR-koden eller kopiera hemligheten till din autentiseringsapp och ange den 6-siffriga koden för att bekräfta.';

  @override
  String get copySecret => 'Kopiera hemlighet';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get sessionLockedTitle => 'Sessionen är låst';

  @override
  String get sessionLockedSubtitle =>
      'Lås upp med PIN eller biometrik för att fortsätta.';

  @override
  String get enterPin => 'Ange PIN';

  @override
  String get unlock => 'Lås upp';

  @override
  String get useBiometrics => 'Använd biometrik';

  @override
  String get acceptTerms => 'Jag accepterar villkoren och integritetspolicyn';

  @override
  String get optional => 'valfritt';

  @override
  String get offers => 'Erbjudanden';

  @override
  String get wallet => 'Plånbok';

  @override
  String get messages => 'Meddelanden';

  @override
  String get search => 'Sök';

  @override
  String get profile => 'Profil';

  @override
  String get buy => 'Köp';

  @override
  String get sell => 'Sälj';

  @override
  String get buying => 'Köper';

  @override
  String get selling => 'Säljer';

  @override
  String get online => 'Online';

  @override
  String get local => 'Lokalt';

  @override
  String get createOffer => 'Skapa erbjudande';

  @override
  String get newOffer => 'Nytt erbjudande';

  @override
  String get editOffer => 'Redigera erbjudande';

  @override
  String get offerType => 'Typ av erbjudande';

  @override
  String get coin => 'Mynt';

  @override
  String get currency => 'Valuta';

  @override
  String get paymentMethod => 'Betalningsmetod';

  @override
  String get priceEquation => 'Prisformel';

  @override
  String get priceEquationHelp =>
      'Använd \'market\' för att följa marknadspriset. Exempel: market*1.02';

  @override
  String get minAmount => 'Minsta belopp';

  @override
  String get maxAmount => 'Högsta belopp';

  @override
  String get country => 'Land';

  @override
  String get city => 'Stad';

  @override
  String get terms => 'Villkor';

  @override
  String get save => 'Spara';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Radera';

  @override
  String get noOffersTitle => 'Inga erbjudanden hittades';

  @override
  String get noOffersHint =>
      'Prova ett annat filter eller skapa ett eget erbjudande.';

  @override
  String get openTrade => 'Öppna handel';

  @override
  String get trade => 'Handel';

  @override
  String get tradeHistory => 'Handelshistorik';

  @override
  String get tradeChat => 'Handelschatt';

  @override
  String get dispute => 'Tvist';

  @override
  String get openDispute => 'Öppna tvist';

  @override
  String get fundEscrow => 'Sätt in i escrow';

  @override
  String get markPaymentSent => 'Markera betalning skickad';

  @override
  String get markPaymentReceived => 'Bekräfta betalning mottagen';

  @override
  String get releaseEscrow => 'Släpp escrow';

  @override
  String get balance => 'Saldo';

  @override
  String get depositAddress => 'Insättningsadress';

  @override
  String get generateNewAddress => 'Generera ny adress';

  @override
  String get withdraw => 'Ta ut';

  @override
  String get destinationAddress => 'Måladress';

  @override
  String get amount => 'Belopp';

  @override
  String get transactionHistory => 'Transaktionshistorik';

  @override
  String get noTransactions => 'Inga transaktioner än';

  @override
  String get send => 'Skicka';

  @override
  String get encryptWithPgp => 'Kryptera med PGP';

  @override
  String get messagePlaceholder => 'Skriv ditt meddelande…';

  @override
  String get notifications => 'Aviseringar';

  @override
  String get markAllRead => 'Markera alla som lästa';

  @override
  String get noNotifications => 'Du har inga olästa aviseringar';

  @override
  String get editProfile => 'Redigera profil';

  @override
  String get publicProfile => 'Offentlig profil';

  @override
  String get feedbackScore => 'Omdömespoäng';

  @override
  String get trades => 'Handlar';

  @override
  String get memberSince => 'Medlem sedan';

  @override
  String get lastSeen => 'Senast sedd';

  @override
  String get trustLevel => 'Förtroendenivå';

  @override
  String get languages => 'Språk';

  @override
  String get savePgpKey => 'Spara PGP-nyckel';

  @override
  String get adminPanel => 'Adminpanel';

  @override
  String get users => 'Användare';

  @override
  String get disputes => 'Tvister';

  @override
  String get moderation => 'Moderering';

  @override
  String get statistics => 'Statistik';

  @override
  String get ban => 'Banna';

  @override
  String get warn => 'Varna';

  @override
  String get verify => 'Verifiera';

  @override
  String get search_hint => 'Sök erbjudanden efter mynt, valuta eller land';

  @override
  String get filter => 'Filter';

  @override
  String get sortByPrice => 'Sortera efter pris';

  @override
  String get sortByReputation => 'Sortera efter rykte';

  @override
  String get sortByRecency => 'Sortera efter nyhet';

  @override
  String get loading => 'Laddar…';

  @override
  String get error => 'Något gick fel';

  @override
  String get retry => 'Försök igen';
}
