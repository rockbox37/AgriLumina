import 'package:agrilumina/l10n/app_localizations.dart';
import 'package:agrilumina/models/user_role.dart';
import 'package:agrilumina/services/location_service.dart';
import 'package:flutter/widgets.dart';

export 'package:agrilumina/l10n/app_localizations.dart';

extension AppLocalizationsX on AppLocalizations {
  String roleLabel(UserRole role) => switch (role) {
        UserRole.seller => roleSeller,
        UserRole.buyer => roleBuyer,
      };

  /// Plural counterpart label for Discover/Home copy (lowercase style).
  String counterpartPlural(UserRole role) => switch (role.counterpart) {
        UserRole.buyer => buyers,
        UserRole.seller => sellers,
      };

  String interestFilterHelper(UserRole role) => role == UserRole.seller
      ? showingCropsYouSell
      : showingCropsYouBuy;

  String locationBannerForStatus(LocationFetchStatus status) =>
      switch (status) {
        LocationFetchStatus.success => sampleListingsEnableLocation,
        LocationFetchStatus.denied => locationPermissionDenied,
        LocationFetchStatus.serviceDisabled => locationServicesOff,
        LocationFetchStatus.unsupported => locationUnsupported,
        LocationFetchStatus.error => locationReadError,
      };
}

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
