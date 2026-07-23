/// Data models for the admin dashboard. These mirror the full (god-mode)
/// backend rows, unlike the public models in lib/models/.
library;

class AdminStats {
  const AdminStats({
    required this.postsByStatus,
    required this.posts24h,
    required this.posts7d,
    required this.reports24h,
    required this.reports7d,
    required this.activeDevices24h,
    required this.activeDevices7d,
    required this.bannedDevices,
    required this.unreadAlerts,
    required this.topReported,
    required this.listingsByRole,
    required this.listingsActive,
    required this.listings24h,
    required this.listings7d,
    required this.contactUnlocks24h,
    required this.contactUnlocks7d,
  });

  final Map<String, int> postsByStatus;
  final int posts24h;
  final int posts7d;
  final int reports24h;
  final int reports7d;
  final int activeDevices24h;
  final int activeDevices7d;
  final int bannedDevices;
  final int unreadAlerts;
  final List<TopReportedPost> topReported;
  final Map<String, int> listingsByRole;
  final int listingsActive;
  final int listings24h;
  final int listings7d;
  final int contactUnlocks24h;
  final int contactUnlocks7d;

  int statusCount(String status) => postsByStatus[status] ?? 0;

  static AdminStats fromJson(Map<String, Object?> json) => AdminStats(
        postsByStatus: (json['posts_by_status'] as Map? ?? {})
            .map((k, v) => MapEntry(k as String, (v as num).toInt())),
        posts24h: (json['posts_24h'] as num?)?.toInt() ?? 0,
        posts7d: (json['posts_7d'] as num?)?.toInt() ?? 0,
        reports24h: (json['reports_24h'] as num?)?.toInt() ?? 0,
        reports7d: (json['reports_7d'] as num?)?.toInt() ?? 0,
        activeDevices24h: (json['active_devices_24h'] as num?)?.toInt() ?? 0,
        activeDevices7d: (json['active_devices_7d'] as num?)?.toInt() ?? 0,
        bannedDevices: (json['banned_devices'] as num?)?.toInt() ?? 0,
        unreadAlerts: (json['unread_alerts'] as num?)?.toInt() ?? 0,
        topReported: (json['top_reported'] as List? ?? [])
            .whereType<Map>()
            .map((m) => TopReportedPost.fromJson(Map<String, Object?>.from(m)))
            .toList(),
        listingsByRole: (json['listings_by_role'] as Map? ?? {})
            .map((k, v) => MapEntry(k as String, (v as num).toInt())),
        listingsActive: (json['listings_active'] as num?)?.toInt() ?? 0,
        listings24h: (json['listings_24h'] as num?)?.toInt() ?? 0,
        listings7d: (json['listings_7d'] as num?)?.toInt() ?? 0,
        contactUnlocks24h:
            (json['contact_unlocks_24h'] as num?)?.toInt() ?? 0,
        contactUnlocks7d: (json['contact_unlocks_7d'] as num?)?.toInt() ?? 0,
      );
}

class TopReportedPost {
  const TopReportedPost({
    required this.id,
    required this.authorName,
    required this.snippet,
    required this.status,
    required this.reportCount,
  });

  final String id;
  final String authorName;
  final String snippet;
  final String status;
  final int reportCount;

  static TopReportedPost fromJson(Map<String, Object?> json) =>
      TopReportedPost(
        id: json['id'] as String? ?? '',
        authorName: json['author_name'] as String? ?? '',
        snippet: json['snippet'] as String? ?? '',
        status: json['status'] as String? ?? '',
        reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
      );
}

/// A forum post with every column, including fields never exposed publicly.
class AdminPost {
  const AdminPost({
    required this.id,
    this.parentId,
    required this.deviceId,
    required this.authorName,
    required this.body,
    required this.status,
    this.hiddenReason,
    required this.spamScore,
    required this.reportCount,
    required this.replyCount,
    required this.createdAt,
  });

  final String id;
  final String? parentId;
  final String deviceId;
  final String authorName;
  final String body;
  final String status;
  final String? hiddenReason;
  final int spamScore;
  final int reportCount;
  final int replyCount;
  final DateTime createdAt;

  static AdminPost? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    if (id is! String || createdAt == null) return null;
    return AdminPost(
      id: id,
      parentId: json['parent_id'] as String?,
      deviceId: json['device_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? '',
      hiddenReason: json['hidden_reason'] as String?,
      spamScore: (json['spam_score'] as num?)?.toInt() ?? 0,
      reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
    );
  }
}

/// A marketplace listing with every column, including phone and device id.
class AdminListing {
  const AdminListing({
    required this.id,
    required this.ownerDeviceId,
    required this.role,
    required this.name,
    required this.crop,
    required this.quantityHint,
    required this.locationText,
    required this.phone,
    required this.updatedAt,
  });

  final String id;
  final String ownerDeviceId;
  final String role;
  final String name;
  final String crop;
  final String quantityHint;
  final String locationText;
  final String phone;
  final DateTime updatedAt;

  /// Read-side expiry horizon used by list_listings (kept in sync manually).
  static const expiryDays = 30;

  bool get expired =>
      DateTime.now().difference(updatedAt).inDays >= expiryDays;

  static AdminListing? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final updatedAt = DateTime.tryParse(json['updated_at'] as String? ?? '');
    if (id is! String || updatedAt == null) return null;
    return AdminListing(
      id: id,
      ownerDeviceId: json['owner_device_id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      name: json['name'] as String? ?? '',
      crop: json['crop'] as String? ?? '',
      quantityHint: json['quantity_hint'] as String? ?? '',
      locationText: json['location_text'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      updatedAt: updatedAt,
    );
  }
}

class PostReport {
  const PostReport({
    required this.reporterDeviceId,
    this.reason,
    required this.createdAt,
  });

  final String reporterDeviceId;
  final String? reason;
  final DateTime createdAt;

  static PostReport fromJson(Map<String, Object?> json) => PostReport(
        reporterDeviceId: json['reporter_device_id'] as String? ?? '',
        reason: json['reason'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class BlocklistEntry {
  const BlocklistEntry({
    required this.id,
    required this.term,
    required this.weight,
    required this.active,
  });

  final int id;
  final String term;
  final int weight;
  final bool active;

  static BlocklistEntry fromJson(Map<String, Object?> json) => BlocklistEntry(
        id: (json['id'] as num).toInt(),
        term: json['term'] as String? ?? '',
        weight: (json['weight'] as num?)?.toInt() ?? 0,
        active: json['active'] as bool? ?? false,
      );
}

class BannedDevice {
  const BannedDevice({
    required this.deviceId,
    this.reason,
    required this.createdAt,
  });

  final String deviceId;
  final String? reason;
  final DateTime createdAt;

  static BannedDevice fromJson(Map<String, Object?> json) => BannedDevice(
        deviceId: json['device_id'] as String? ?? '',
        reason: json['reason'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class AdminAlert {
  const AdminAlert({
    required this.id,
    required this.ruleId,
    this.subjectPostId,
    required this.detail,
    required this.read,
    required this.createdAt,
  });

  final int id;
  final String ruleId;
  final String? subjectPostId;
  final Map<String, Object?> detail;
  final bool read;
  final DateTime createdAt;

  static AdminAlert fromJson(Map<String, Object?> json) => AdminAlert(
        id: (json['id'] as num).toInt(),
        ruleId: json['rule_id'] as String? ?? '',
        subjectPostId: json['subject_post_id'] as String?,
        detail: json['detail'] is Map
            ? Map<String, Object?>.from(json['detail'] as Map)
            : const {},
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class AlertRule {
  const AlertRule({
    required this.id,
    required this.enabled,
    this.threshold,
  });

  final String id;
  final bool enabled;

  /// Events per hour; null for non-spike rules.
  final int? threshold;

  static AlertRule fromJson(Map<String, Object?> json) => AlertRule(
        id: json['id'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        threshold: (json['threshold'] as num?)?.toInt(),
      );
}
