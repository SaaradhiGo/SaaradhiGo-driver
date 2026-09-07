import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_type_converters.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

enum NotificationCategory {
  all,
  trips,
  earnings,
  system,
  safety;

  String get label {
    switch (this) {
      case NotificationCategory.all:
        return 'All';
      case NotificationCategory.trips:
        return 'Trips';
      case NotificationCategory.earnings:
        return 'Earnings';
      case NotificationCategory.system:
        return 'System';
      case NotificationCategory.safety:
        return 'Safety';
    }
  }
}

@freezed
abstract class NotificationModel with _$NotificationModel {
  const NotificationModel._();

  const factory NotificationModel({
    @JsonKey(fromJson: intFromJson) required int id,
    @Default('') String title,
    @Default('') String message,
    @JsonKey(name: 'is_read', fromJson: boolFromJson)
    @Default(false)
    bool isRead,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String? type,
    Map<String, dynamic>? data,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Resolves the semantic category of this notification.
  NotificationCategory get category {
    final t = (type ?? '').toLowerCase().trim();
    if (t.contains('earning') || t.contains('wallet') || t.contains('payout')) {
      return NotificationCategory.earnings;
    }
    if (t.contains('trip') || t.contains('ride') || t.contains('dispatch')) {
      return NotificationCategory.trips;
    }
    if (t.contains('safety') ||
        t.contains('sos') ||
        t.contains('incident') ||
        t.contains('emergency') ||
        t.contains('expiry') ||
        t.contains('document')) {
      return NotificationCategory.safety;
    }
    if (t.contains('system') ||
        t.contains('verify') ||
        t.contains('account') ||
        t.contains('profile')) {
      return NotificationCategory.system;
    }

    // Fallback based on title & message keywords
    final combined = '${title.toLowerCase()} ${message.toLowerCase()}';
    if (combined.contains('₹') ||
        combined.contains('wallet') ||
        combined.contains('earning') ||
        combined.contains('bonus') ||
        combined.contains('payout')) {
      return NotificationCategory.earnings;
    }
    if (combined.contains('trip') ||
        combined.contains('ride') ||
        combined.contains('pickup') ||
        combined.contains('drop')) {
      return NotificationCategory.trips;
    }
    if (combined.contains('safety') ||
        combined.contains('sos') ||
        combined.contains('insurance') ||
        combined.contains('expiry') ||
        combined.contains('action required') ||
        combined.contains('document')) {
      return NotificationCategory.safety;
    }
    return NotificationCategory.system;
  }
}
