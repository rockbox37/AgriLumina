/// Types for remote listing sync and contact unlock.
library;

/// Pending remote operation for one role's listing. At most one per role:
/// the payload is derived from current local state at flush time, so a later
/// publish/clear simply overwrites the queued op (last write wins).
enum PendingListingOp { upsert, delete }

class PendingListingSync {
  PendingListingSync({required this.op, this.failed = false});

  PendingListingOp op;

  /// True when the last flush attempt got a non-offline API error.
  bool failed;

  Map<String, Object?> toJson() => {'op': op.name, 'failed': failed};

  static PendingListingSync? fromJson(Map<String, Object?> json) {
    final op = switch (json['op']) {
      'upsert' => PendingListingOp.upsert,
      'delete' => PendingListingOp.delete,
      _ => null,
    };
    if (op == null) return null;
    return PendingListingSync(op: op, failed: json['failed'] == true);
  }
}

/// Derived per-role sync status shown in the UI.
enum ListingSyncStatus { synced, pending, failed }

/// Where the Discover feed is currently sourced from.
enum DiscoverFeedSource { remote, cache, seed }

enum ContactUnlockStatus {
  unlocked,
  noCredits,
  offline,
  rateLimited,
  notFound,
  error,
}

class ContactUnlockResult {
  const ContactUnlockResult(this.status, [this.phone]);

  final ContactUnlockStatus status;
  final String? phone;

  bool get ok => status == ContactUnlockStatus.unlocked;
}
