// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'CapitalMonero';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get recoverAccount => 'Récupérer le compte';

  @override
  String get recoveryInstructions =>
      'Entrez votre phrase de récupération de 12 mots pour retrouver l\'accès à votre compte et définir un nouveau mot de passe.';

  @override
  String get mnemonicPhrase => 'Phrase de récupération';

  @override
  String get twoFactorCode => 'Code à deux facteurs';

  @override
  String get twoFactorSetup => 'Configurer l\'authentification à deux facteurs';

  @override
  String get twoFactorSetupIntro =>
      'Scannez le QR code ou copiez le secret dans votre application d\'authentification, puis saisissez le code à 6 chiffres pour confirmer.';

  @override
  String get copySecret => 'Copier le secret';

  @override
  String get confirm => 'Confirmer';

  @override
  String get sessionLockedTitle => 'Session verrouillée';

  @override
  String get sessionLockedSubtitle =>
      'Déverrouillez avec votre PIN ou la biométrie pour continuer.';

  @override
  String get enterPin => 'Saisissez le PIN';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get useBiometrics => 'Utiliser la biométrie';

  @override
  String get acceptTerms =>
      'J\'accepte les conditions générales et la politique de confidentialité';

  @override
  String get optional => 'facultatif';

  @override
  String get offers => 'Offres';

  @override
  String get wallet => 'Portefeuille';

  @override
  String get messages => 'Messages';

  @override
  String get search => 'Rechercher';

  @override
  String get profile => 'Profil';

  @override
  String get buy => 'Acheter';

  @override
  String get sell => 'Vendre';

  @override
  String get buying => 'Achat';

  @override
  String get selling => 'Vente';

  @override
  String get online => 'En ligne';

  @override
  String get local => 'Local';

  @override
  String get createOffer => 'Créer une offre';

  @override
  String get newOffer => 'Nouvelle offre';

  @override
  String get editOffer => 'Modifier l\'offre';

  @override
  String get offerType => 'Type d\'offre';

  @override
  String get coin => 'Crypto';

  @override
  String get currency => 'Devise';

  @override
  String get paymentMethod => 'Mode de paiement';

  @override
  String get priceEquation => 'Équation de prix';

  @override
  String get priceEquationHelp =>
      'Utilisez \'market\' pour suivre le cours en direct. Exemple : market*1.02';

  @override
  String get minAmount => 'Montant minimum';

  @override
  String get maxAmount => 'Montant maximum';

  @override
  String get country => 'Pays';

  @override
  String get city => 'Ville';

  @override
  String get terms => 'Conditions';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get noOffersTitle => 'Aucune offre trouvée';

  @override
  String get noOffersHint =>
      'Essayez un autre filtre ou créez votre propre offre.';

  @override
  String get openTrade => 'Ouvrir une transaction';

  @override
  String get trade => 'Transaction';

  @override
  String get tradeHistory => 'Historique des transactions';

  @override
  String get tradeChat => 'Discussion de transaction';

  @override
  String get dispute => 'Litige';

  @override
  String get openDispute => 'Ouvrir un litige';

  @override
  String get fundEscrow => 'Approvisionner l\'escrow';

  @override
  String get markPaymentSent => 'Paiement envoyé';

  @override
  String get markPaymentReceived => 'Paiement reçu';

  @override
  String get releaseEscrow => 'Libérer l\'escrow';

  @override
  String get balance => 'Solde';

  @override
  String get depositAddress => 'Adresse de dépôt';

  @override
  String get generateNewAddress => 'Générer une nouvelle adresse';

  @override
  String get withdraw => 'Retirer';

  @override
  String get destinationAddress => 'Adresse de destination';

  @override
  String get amount => 'Montant';

  @override
  String get transactionHistory => 'Historique des transactions';

  @override
  String get noTransactions => 'Aucune transaction pour le moment';

  @override
  String get send => 'Envoyer';

  @override
  String get encryptWithPgp => 'Chiffrer avec PGP';

  @override
  String get messagePlaceholder => 'Saisissez votre message…';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Tout marquer comme lu';

  @override
  String get noNotifications => 'Vous êtes à jour';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get publicProfile => 'Profil public';

  @override
  String get feedbackScore => 'Score de feedback';

  @override
  String get trades => 'Transactions';

  @override
  String get memberSince => 'Membre depuis';

  @override
  String get lastSeen => 'Vu pour la dernière fois';

  @override
  String get trustLevel => 'Niveau de confiance';

  @override
  String get languages => 'Langues';

  @override
  String get savePgpKey => 'Enregistrer la clé PGP';

  @override
  String get adminPanel => 'Panneau d\'administration';

  @override
  String get users => 'Utilisateurs';

  @override
  String get disputes => 'Litiges';

  @override
  String get moderation => 'Modération';

  @override
  String get statistics => 'Statistiques';

  @override
  String get ban => 'Bannir';

  @override
  String get warn => 'Avertir';

  @override
  String get verify => 'Vérifier';

  @override
  String get search_hint => 'Rechercher des offres par crypto, devise ou pays';

  @override
  String get filter => 'Filtrer';

  @override
  String get sortByPrice => 'Trier par prix';

  @override
  String get sortByReputation => 'Trier par réputation';

  @override
  String get sortByRecency => 'Trier par récence';

  @override
  String get loading => 'Chargement…';

  @override
  String get error => 'Une erreur s\'est produite';

  @override
  String get retry => 'Réessayer';
}
