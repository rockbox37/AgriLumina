import 'package:agrilumina/l10n/app_localizations.dart';

enum UserRole {
  seller,
  buyer;

  String label(AppLocalizations l10n) => switch (this) {
        UserRole.seller => l10n.roleSeller,
        UserRole.buyer => l10n.roleBuyer,
      };

  /// The role we want to discover on the Discover tab.
  UserRole get counterpart => switch (this) {
        UserRole.seller => UserRole.buyer,
        UserRole.buyer => UserRole.seller,
      };
}
