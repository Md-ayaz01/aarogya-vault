// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardSummaryImpl _$$DashboardSummaryImplFromJson(
  Map<String, dynamic> json,
) => _$DashboardSummaryImpl(
  userName: json['userName'] as String,
  avatarUrl: json['avatarUrl'] as String? ?? '',
  metrics: (json['metrics'] as List<dynamic>)
      .map((e) => DashboardMetric.fromJson(e as Map<String, dynamic>))
      .toList(),
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => DashboardNotification.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$DashboardSummaryImplToJson(
  _$DashboardSummaryImpl instance,
) => <String, dynamic>{
  'userName': instance.userName,
  'avatarUrl': instance.avatarUrl,
  'metrics': instance.metrics,
  'notifications': instance.notifications,
};

_$DashboardMetricImpl _$$DashboardMetricImplFromJson(
  Map<String, dynamic> json,
) => _$DashboardMetricImpl(
  label: json['label'] as String,
  value: json['value'] as String,
  unit: json['unit'] as String? ?? '',
  icon: json['icon'] as String? ?? '',
);

Map<String, dynamic> _$$DashboardMetricImplToJson(
  _$DashboardMetricImpl instance,
) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
  'unit': instance.unit,
  'icon': instance.icon,
};

_$DashboardNotificationImpl _$$DashboardNotificationImplFromJson(
  Map<String, dynamic> json,
) => _$DashboardNotificationImpl(
  title: json['title'] as String,
  body: json['body'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$DashboardNotificationImplToJson(
  _$DashboardNotificationImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'body': instance.body,
  'timestamp': instance.timestamp.toIso8601String(),
};
