enum UserRole {
  seller,
  buyer;

  String get label => switch (this) {
        UserRole.seller => 'Seller',
        UserRole.buyer => 'Buyer',
      };

  /// The role we want to discover on the Discover tab.
  UserRole get counterpart => switch (this) {
        UserRole.seller => UserRole.buyer,
        UserRole.buyer => UserRole.seller,
      };
}
