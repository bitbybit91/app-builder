// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class AppLocalizationsNo extends AppLocalizations {
  AppLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get appName => 'CapitalMonero';

  @override
  String get username => 'Brukernavn';

  @override
  String get email => 'E-post';

  @override
  String get password => 'Passord';

  @override
  String get confirmPassword => 'Bekreft passord';

  @override
  String get newPassword => 'Nytt passord';

  @override
  String get signIn => 'Logg inn';

  @override
  String get signOut => 'Logg ut';

  @override
  String get createAccount => 'Opprett konto';

  @override
  String get forgotPassword => 'Glemt passord?';

  @override
  String get recoverAccount => 'Gjenopprett konto';

  @override
  String get recoveryInstructions =>
      'Skriv inn din 12-ords gjenopprettingsfrase for å få tilgang til kontoen igjen og sette nytt passord.';

  @override
  String get mnemonicPhrase => 'Gjenopprettingsfrase';

  @override
  String get twoFactorCode => 'Tofaktor-kode';

  @override
  String get twoFactorSetup => 'Konfigurer tofaktorautentisering';

  @override
  String get twoFactorSetupIntro =>
      'Skann QR-koden eller kopier hemmeligheten inn i autentiseringsappen og skriv inn den 6-sifrede koden for å bekrefte.';

  @override
  String get copySecret => 'Kopier hemmelighet';

  @override
  String get confirm => 'Bekreft';

  @override
  String get sessionLockedTitle => 'Økten er låst';

  @override
  String get sessionLockedSubtitle =>
      'Lås opp med PIN eller biometri for å fortsette.';

  @override
  String get enterPin => 'Skriv inn PIN';

  @override
  String get unlock => 'Lås opp';

  @override
  String get useBiometrics => 'Bruk biometri';

  @override
  String get acceptTerms => 'Jeg godtar vilkårene og personvernerklæringen';

  @override
  String get optional => 'valgfritt';

  @override
  String get offers => 'Tilbud';

  @override
  String get wallet => 'Lommebok';

  @override
  String get messages => 'Meldinger';

  @override
  String get search => 'Søk';

  @override
  String get profile => 'Profil';

  @override
  String get buy => 'Kjøp';

  @override
  String get sell => 'Selg';

  @override
  String get buying => 'Kjøper';

  @override
  String get selling => 'Selger';

  @override
  String get online => 'På nett';

  @override
  String get local => 'Lokalt';

  @override
  String get createOffer => 'Opprett tilbud';

  @override
  String get newOffer => 'Nytt tilbud';

  @override
  String get editOffer => 'Rediger tilbud';

  @override
  String get offerType => 'Tilbudstype';

  @override
  String get coin => 'Mynt';

  @override
  String get currency => 'Valuta';

  @override
  String get paymentMethod => 'Betalingsmåte';

  @override
  String get priceEquation => 'Prisformel';

  @override
  String get priceEquationHelp =>
      'Bruk \'market\' for å følge markedsprisen. Eksempel: market*1.02';

  @override
  String get minAmount => 'Minste beløp';

  @override
  String get maxAmount => 'Største beløp';

  @override
  String get country => 'Land';

  @override
  String get city => 'By';

  @override
  String get terms => 'Vilkår';

  @override
  String get save => 'Lagre';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Slett';

  @override
  String get noOffersTitle => 'Ingen tilbud funnet';

  @override
  String get noOffersHint =>
      'Prøv et annet filter eller opprett ditt eget tilbud.';

  @override
  String get openTrade => 'Åpne handel';

  @override
  String get trade => 'Handel';

  @override
  String get tradeHistory => 'Handelshistorikk';

  @override
  String get tradeChat => 'Handelschat';

  @override
  String get dispute => 'Tvist';

  @override
  String get openDispute => 'Åpne tvist';

  @override
  String get fundEscrow => 'Sett inn i escrow';

  @override
  String get markPaymentSent => 'Marker betaling sendt';

  @override
  String get markPaymentReceived => 'Bekreft mottatt betaling';

  @override
  String get releaseEscrow => 'Frigi escrow';

  @override
  String get balance => 'Saldo';

  @override
  String get depositAddress => 'Innskuddsadresse';

  @override
  String get generateNewAddress => 'Generer ny adresse';

  @override
  String get withdraw => 'Ta ut';

  @override
  String get destinationAddress => 'Mottakeradresse';

  @override
  String get amount => 'Beløp';

  @override
  String get transactionHistory => 'Transaksjonshistorikk';

  @override
  String get noTransactions => 'Ingen transaksjoner ennå';

  @override
  String get send => 'Send';

  @override
  String get encryptWithPgp => 'Krypter med PGP';

  @override
  String get messagePlaceholder => 'Skriv meldingen din…';

  @override
  String get notifications => 'Varsler';

  @override
  String get markAllRead => 'Merk alle som lest';

  @override
  String get noNotifications => 'Du er à jour';

  @override
  String get editProfile => 'Rediger profil';

  @override
  String get publicProfile => 'Offentlig profil';

  @override
  String get feedbackScore => 'Tilbakemeldingsscore';

  @override
  String get trades => 'Handler';

  @override
  String get memberSince => 'Medlem siden';

  @override
  String get lastSeen => 'Sist sett';

  @override
  String get trustLevel => 'Tillitsnivå';

  @override
  String get languages => 'Språk';

  @override
  String get savePgpKey => 'Lagre PGP-nøkkel';

  @override
  String get adminPanel => 'Administrasjonspanel';

  @override
  String get users => 'Brukere';

  @override
  String get disputes => 'Tvister';

  @override
  String get moderation => 'Moderering';

  @override
  String get statistics => 'Statistikk';

  @override
  String get ban => 'Utesteng';

  @override
  String get warn => 'Advar';

  @override
  String get verify => 'Verifiser';

  @override
  String get search_hint => 'Søk tilbud etter mynt, valuta eller land';

  @override
  String get filter => 'Filter';

  @override
  String get sortByPrice => 'Sorter etter pris';

  @override
  String get sortByReputation => 'Sorter etter omdømme';

  @override
  String get sortByRecency => 'Sorter etter nyeste';

  @override
  String get loading => 'Laster…';

  @override
  String get error => 'Noe gikk galt';

  @override
  String get retry => 'Prøv igjen';
}
