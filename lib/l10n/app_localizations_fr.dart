// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'AgriLumina';

  @override
  String get navHome => 'Accueil';

  @override
  String get navDiscover => 'Découvrir';

  @override
  String get navCredits => 'Crédits';

  @override
  String get navProfile => 'Profil';

  @override
  String get brandHomeTooltip => 'Accueil';

  @override
  String get brandHomeSemantics => 'Accueil AgriLumina';

  @override
  String creditsCount(int count) {
    return '$count crédits';
  }

  @override
  String welcomeUser(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String findNearbyByDistance(String counterpart) {
    return 'Trouvez des $counterpart à proximité par distance.';
  }

  @override
  String get buyers => 'acheteurs';

  @override
  String get sellers => 'vendeurs';

  @override
  String get iAmA => 'Je suis…';

  @override
  String get roleSeller => 'Vendeur';

  @override
  String get roleBuyer => 'Acheteur';

  @override
  String nearbyCount(int count, String counterpart) {
    return '$count $counterpart à proximité';
  }

  @override
  String get noMatchesInSeedData =>
      'Aucune correspondance dans les données d’exemple';

  @override
  String closestListing(String name, String distance) {
    return 'Le plus proche : $name · $distance';
  }

  @override
  String spendCreditToUnlock(int cost) {
    return 'Dépensez $cost crédit pour déverrouiller un numéro.';
  }

  @override
  String get findBuyers => 'Trouver des acheteurs';

  @override
  String get findSellers => 'Trouver des vendeurs';

  @override
  String get refreshLocation => 'Actualiser la position';

  @override
  String get filterAll => 'Tous';

  @override
  String get showingCropsYouSell => 'Cultures que vous vendez';

  @override
  String get showingCropsYouBuy => 'Cultures que vous achetez';

  @override
  String searchCounterparts(String counterpart) {
    return 'Rechercher des $counterpart';
  }

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String noCounterpartsNearbyYet(String counterpart) {
    return 'Aucun $counterpart à proximité pour l’instant.';
  }

  @override
  String noCropCounterpartsNearby(String crop, String counterpart) {
    return 'Aucun $counterpart de $crop à proximité.';
  }

  @override
  String noCounterpartsForInterests(String counterpart) {
    return 'Aucun $counterpart à proximité pour vos intérêts.';
  }

  @override
  String noCounterpartsNearby(String counterpart) {
    return 'Aucun $counterpart à proximité.';
  }

  @override
  String noSearchMatches(String query, String scope) {
    return 'Aucun résultat pour « $query » parmi $scope.';
  }

  @override
  String nearYouBanner(String label) {
    return 'Près de vous · $label';
  }

  @override
  String get sampleListingsEnableLocation =>
      'Annonces d’exemple · activez la localisation pour les distances';

  @override
  String get locationPermissionDenied =>
      'Permission de localisation refusée. Distances depuis les annonces d’exemple.';

  @override
  String get locationServicesOff =>
      'Services de localisation désactivés. Distances depuis les annonces d’exemple.';

  @override
  String get locationUnsupported =>
      'GPS indisponible sur cet appareil. Distances depuis les annonces d’exemple.';

  @override
  String get locationReadError =>
      'Impossible de lire la position. Distances depuis les annonces d’exemple.';

  @override
  String get sampleArea => 'Zone d’exemple';

  @override
  String get nearSampleArea => 'Près de la zone d’exemple';

  @override
  String get yourCurrentLocation => 'Votre position actuelle';

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String get listingTitle => 'Annonce';

  @override
  String get listingNotFound => 'Annonce introuvable.';

  @override
  String get labelRole => 'Rôle';

  @override
  String get labelLocation => 'Lieu';

  @override
  String get labelDistance => 'Distance';

  @override
  String get labelLastActive => 'Dernière activité';

  @override
  String get contact => 'Contact';

  @override
  String get call => 'Appeler';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get opensDialerOrWhatsApp =>
      'Ouvre le composeur ou WhatsApp. Pas de chat dans l’app.';

  @override
  String phoneLockedSpendCredit(int cost) {
    return 'Numéro verrouillé. Dépensez $cost crédit pour déverrouiller.';
  }

  @override
  String get contactUnlocked => 'Contact déverrouillé.';

  @override
  String get notEnoughCredits =>
      'Pas assez de crédits. Ajoutez-en dans l’onglet Crédits.';

  @override
  String unlockForCredit(int cost) {
    return 'Déverrouiller pour $cost crédit';
  }

  @override
  String youHaveCredits(int count) {
    return 'Vous avez $count crédits.';
  }

  @override
  String get couldNotOpenDialer =>
      'Impossible d’ouvrir le composeur sur cet appareil.';

  @override
  String get couldNotOpenWhatsApp =>
      'Impossible d’ouvrir WhatsApp. Installez WhatsApp ou utilisez Appeler.';

  @override
  String get yourBalance => 'Votre solde';

  @override
  String creditsExplainer(int cost) {
    return 'Déverrouiller un contact coûte $cost crédit. Les paiements réels viendront plus tard — pour l’instant, ajoutez des crédits de démo.';
  }

  @override
  String addedDemoCredits(int count) {
    return '$count crédits de démo ajoutés.';
  }

  @override
  String addDemoCredits(int count) {
    return 'Ajouter $count crédits de démo';
  }

  @override
  String addedDemoCredit(int count) {
    return '$count crédit de démo ajouté.';
  }

  @override
  String addDemoCredit(int count) {
    return 'Ajouter $count crédit de démo';
  }

  @override
  String get displayName => 'Nom affiché';

  @override
  String get buyingInterests => 'Intérêts d’achat';

  @override
  String get sellingInterests => 'Intérêts de vente';

  @override
  String get buyingInterestsEmpty =>
      'Aucun pour l’instant — ajoutez des cultures à acheter';

  @override
  String get sellingInterestsEmpty =>
      'Aucun pour l’instant — ajoutez des cultures à vendre';

  @override
  String get profileSaved => 'Profil enregistré.';

  @override
  String get saveProfile => 'Enregistrer le profil';

  @override
  String profileStats(int credits, int unlocked) {
    return 'Crédits : $credits · Contacts déverrouillés : $unlocked';
  }

  @override
  String get defaultDisplayName => 'Vous';

  @override
  String get defaultLocation => 'Non défini';

  @override
  String listingSubtitle(
    String crop,
    String quantity,
    String distance,
    String lastActive,
  ) {
    return '$crop · $quantity\n$distance · $lastActive';
  }
}
