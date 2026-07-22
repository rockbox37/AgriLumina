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
  String get lookingFor => 'Je cherche…';

  @override
  String get lookingForBuyers => 'Acheteurs';

  @override
  String get lookingForSellers => 'Vendeurs';

  @override
  String get enabledRolesLabel => 'Je peux…';

  @override
  String get rolesRequired => 'Sélectionnez au moins un rôle.';

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
  String get publicTagline => 'Slogan public';

  @override
  String get taglineHint => 'ex. Ferme 100 % bio';

  @override
  String taglineTooLong(int max) {
    return 'Le slogan doit comporter au plus $max caractères.';
  }

  @override
  String get labelTagline => 'Slogan';

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
  String get addCropInterest => 'Ajouter une culture';

  @override
  String get addCropInterestHint =>
      'Saisissez un nom ou choisissez une suggestion';

  @override
  String didYouMeanCrop(String crop) {
    return 'Vouliez-vous dire $crop ?';
  }

  @override
  String useSuggestedCrop(String crop) {
    return 'Utiliser $crop';
  }

  @override
  String addCropAsTyped(String crop) {
    return 'Ajouter « $crop » quand même';
  }

  @override
  String addedCanonicalCrop(String crop) {
    return 'Ajouté sous $crop.';
  }

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
  String get myListing => 'Mon annonce';

  @override
  String get publishMyListing => 'Publier mon annonce';

  @override
  String get editMyListing => 'Modifier mon annonce';

  @override
  String get clearMyListing => 'Supprimer l’annonce';

  @override
  String get listingPublished => 'Annonce publiée.';

  @override
  String get listingCleared => 'Annonce supprimée.';

  @override
  String get labelCrop => 'Culture';

  @override
  String get labelQuantity => 'Quantité';

  @override
  String get labelPhone => 'Téléphone';

  @override
  String get quantityHintField => 'ex. ~800 kg prêts';

  @override
  String get phoneHintField => 'Numéro pour Appeler / WhatsApp';

  @override
  String get saveListing => 'Enregistrer l’annonce';

  @override
  String get myListingEmpty => 'Aucune annonce pour ce rôle.';

  @override
  String myListingSummary(String crop, String quantity) {
    return '$crop · $quantity';
  }

  @override
  String listingSubtitle(
    String crop,
    String quantity,
    String distance,
    String lastActive,
  ) {
    return '$crop · $quantity\n$distance · $lastActive';
  }

  @override
  String get cropMaize => 'Maïs';

  @override
  String get cropCassava => 'Manioc';

  @override
  String get cropBeans => 'Haricots';

  @override
  String get cropGroundnuts => 'Arachides';

  @override
  String get cropRice => 'Riz';

  @override
  String get qtyBuyingUpTo2Tonnes => 'Achète jusqu’à 2 tonnes';

  @override
  String get qtyWeeklyBuyerBags => 'Acheteur hebdomadaire · sacs';

  @override
  String get qtyAggregatorFairPrice => 'Agrégateur · prix équitable';

  @override
  String get qtyNeeds500KgThisWeek => 'Besoin de 500 kg cette semaine';

  @override
  String get qtySmallLotsWelcome => 'Petits lots bienvenus';

  @override
  String get qty800KgReady => '~800 kg prêts';

  @override
  String get qtyFreshHarvest => 'Récolte fraîche';

  @override
  String get qty10Bags => '10 sacs';

  @override
  String get qty1_5Tonnes => '1,5 tonnes';

  @override
  String get qtySmallSurplus => 'Petit surplus';

  @override
  String get placeVillageMarket => 'Marché du village';

  @override
  String get placeNearVillage => 'Près du village';

  @override
  String get placeKaleheRoad => 'Route de Kalehe';

  @override
  String get placeVillage => 'Village';

  @override
  String get placeNearbyHills => 'Collines proches';

  @override
  String get placeNearKalehe => 'Près de Kalehe';

  @override
  String get activeToday => 'Actif aujourd’hui';

  @override
  String get activeYesterday => 'Actif hier';

  @override
  String get active2DaysAgo => 'Actif il y a 2 jours';

  @override
  String get active3DaysAgo => 'Actif il y a 3 jours';

  @override
  String get activeThisWeek => 'Actif cette semaine';

  @override
  String get navForum => 'Forum';

  @override
  String get forumTitle => 'Forum communautaire';

  @override
  String get forumNewPost => 'Nouvelle publication';

  @override
  String get forumPostHint =>
      'Partagez des nouvelles, des prix ou des questions…';

  @override
  String get forumPostAction => 'Publier';

  @override
  String get forumReplyAction => 'Répondre';

  @override
  String get forumReplyHint => 'Écrivez une réponse…';

  @override
  String get forumReportSpam => 'C\'est du spam';

  @override
  String get forumReported => 'Signalé';

  @override
  String get forumReportThanks => 'Merci — cette publication a été signalée.';

  @override
  String get forumDeletePost => 'Supprimer la publication';

  @override
  String get forumDeleteConfirm => 'Supprimer cette publication ?';

  @override
  String get forumPostDeleted => 'Publication supprimée.';

  @override
  String get forumPendingReview => 'En attente de vérification';

  @override
  String get forumPendingExplainer =>
      'Vous seul pouvez voir ceci avant vérification.';

  @override
  String get forumOfflineBanner =>
      'Vous êtes hors ligne — publications enregistrées.';

  @override
  String get forumEmpty =>
      'Aucune publication pour l\'instant. Lancez la discussion !';

  @override
  String get forumLoadError =>
      'Impossible de charger les publications. Tirez pour réessayer.';

  @override
  String forumRateLimited(int seconds) {
    return 'Vous publiez trop vite. Réessayez dans $seconds s.';
  }

  @override
  String get forumDuplicate => 'Vous avez déjà publié ceci récemment.';

  @override
  String get forumPostFailed =>
      'Publication impossible. Vérifiez votre connexion et réessayez.';

  @override
  String forumReplies(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réponses',
      one: '1 réponse',
      zero: 'Aucune réponse',
    );
    return '$_temp0';
  }

  @override
  String get forumLoadMore => 'Charger plus';

  @override
  String get forumThreadTitle => 'Discussion';

  @override
  String get forumSetNameFirst =>
      'Ajoutez votre nom dans le Profil avant de publier.';

  @override
  String get forumJustNow => 'à l\'instant';

  @override
  String forumMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String forumHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String forumDaysAgo(int days) {
    return 'il y a $days j';
  }
}
