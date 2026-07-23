// lib/models/dashboard_summary.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';
part 'dashboard_summary.g.dart';

@freezed
class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required String userName,
    @Default('') String avatarUrl,
    required List<DashboardMetric> metrics,
    required List<DashboardNotification> notifications,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => _$DashboardSummaryFromJson(json);
}

@freezed
class DashboardMetric with _$DashboardMetric {
  const factory DashboardMetric({
    required String label,
    required String value,
    @Default('') String unit,
    @Default('') String icon, // optional icon name
  }) = _DashboardMetric;

  factory DashboardMetric.fromJson(Map<String, dynamic> json) => _$DashboardMetricFromJson(json);
}

@freezed
class DashboardNotification with _$DashboardNotification {
  const factory DashboardNotification({
    required String title,
    required String body,
    required DateTime timestamp,
  }) = _DashboardNotification;

  factory DashboardNotification.fromJson(Map<String, dynamic> json) => _$DashboardNotificationFromJson(json);
}
