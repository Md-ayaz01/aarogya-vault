// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) {
  return _DashboardSummary.fromJson(json);
}

/// @nodoc
mixin _$DashboardSummary {
  String get userName => throw _privateConstructorUsedError;
  String get avatarUrl => throw _privateConstructorUsedError;
  List<DashboardMetric> get metrics => throw _privateConstructorUsedError;
  List<DashboardNotification> get notifications =>
      throw _privateConstructorUsedError;

  /// Serializes this DashboardSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardSummaryCopyWith<DashboardSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardSummaryCopyWith<$Res> {
  factory $DashboardSummaryCopyWith(
    DashboardSummary value,
    $Res Function(DashboardSummary) then,
  ) = _$DashboardSummaryCopyWithImpl<$Res, DashboardSummary>;
  @useResult
  $Res call({
    String userName,
    String avatarUrl,
    List<DashboardMetric> metrics,
    List<DashboardNotification> notifications,
  });
}

/// @nodoc
class _$DashboardSummaryCopyWithImpl<$Res, $Val extends DashboardSummary>
    implements $DashboardSummaryCopyWith<$Res> {
  _$DashboardSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userName = null,
    Object? avatarUrl = null,
    Object? metrics = null,
    Object? notifications = null,
  }) {
    return _then(
      _value.copyWith(
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            avatarUrl: null == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            metrics: null == metrics
                ? _value.metrics
                : metrics // ignore: cast_nullable_to_non_nullable
                      as List<DashboardMetric>,
            notifications: null == notifications
                ? _value.notifications
                : notifications // ignore: cast_nullable_to_non_nullable
                      as List<DashboardNotification>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardSummaryImplCopyWith<$Res>
    implements $DashboardSummaryCopyWith<$Res> {
  factory _$$DashboardSummaryImplCopyWith(
    _$DashboardSummaryImpl value,
    $Res Function(_$DashboardSummaryImpl) then,
  ) = __$$DashboardSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userName,
    String avatarUrl,
    List<DashboardMetric> metrics,
    List<DashboardNotification> notifications,
  });
}

/// @nodoc
class __$$DashboardSummaryImplCopyWithImpl<$Res>
    extends _$DashboardSummaryCopyWithImpl<$Res, _$DashboardSummaryImpl>
    implements _$$DashboardSummaryImplCopyWith<$Res> {
  __$$DashboardSummaryImplCopyWithImpl(
    _$DashboardSummaryImpl _value,
    $Res Function(_$DashboardSummaryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userName = null,
    Object? avatarUrl = null,
    Object? metrics = null,
    Object? notifications = null,
  }) {
    return _then(
      _$DashboardSummaryImpl(
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarUrl: null == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        metrics: null == metrics
            ? _value._metrics
            : metrics // ignore: cast_nullable_to_non_nullable
                  as List<DashboardMetric>,
        notifications: null == notifications
            ? _value._notifications
            : notifications // ignore: cast_nullable_to_non_nullable
                  as List<DashboardNotification>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardSummaryImpl implements _DashboardSummary {
  const _$DashboardSummaryImpl({
    required this.userName,
    this.avatarUrl = '',
    required final List<DashboardMetric> metrics,
    required final List<DashboardNotification> notifications,
  }) : _metrics = metrics,
       _notifications = notifications;

  factory _$DashboardSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardSummaryImplFromJson(json);

  @override
  final String userName;
  @override
  @JsonKey()
  final String avatarUrl;
  final List<DashboardMetric> _metrics;
  @override
  List<DashboardMetric> get metrics {
    if (_metrics is EqualUnmodifiableListView) return _metrics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_metrics);
  }

  final List<DashboardNotification> _notifications;
  @override
  List<DashboardNotification> get notifications {
    if (_notifications is EqualUnmodifiableListView) return _notifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notifications);
  }

  @override
  String toString() {
    return 'DashboardSummary(userName: $userName, avatarUrl: $avatarUrl, metrics: $metrics, notifications: $notifications)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardSummaryImpl &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            const DeepCollectionEquality().equals(other._metrics, _metrics) &&
            const DeepCollectionEquality().equals(
              other._notifications,
              _notifications,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userName,
    avatarUrl,
    const DeepCollectionEquality().hash(_metrics),
    const DeepCollectionEquality().hash(_notifications),
  );

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardSummaryImplCopyWith<_$DashboardSummaryImpl> get copyWith =>
      __$$DashboardSummaryImplCopyWithImpl<_$DashboardSummaryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardSummaryImplToJson(this);
  }
}

abstract class _DashboardSummary implements DashboardSummary {
  const factory _DashboardSummary({
    required final String userName,
    final String avatarUrl,
    required final List<DashboardMetric> metrics,
    required final List<DashboardNotification> notifications,
  }) = _$DashboardSummaryImpl;

  factory _DashboardSummary.fromJson(Map<String, dynamic> json) =
      _$DashboardSummaryImpl.fromJson;

  @override
  String get userName;
  @override
  String get avatarUrl;
  @override
  List<DashboardMetric> get metrics;
  @override
  List<DashboardNotification> get notifications;

  /// Create a copy of DashboardSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardSummaryImplCopyWith<_$DashboardSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DashboardMetric _$DashboardMetricFromJson(Map<String, dynamic> json) {
  return _DashboardMetric.fromJson(json);
}

/// @nodoc
mixin _$DashboardMetric {
  String get label => throw _privateConstructorUsedError;
  String get value => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;

  /// Serializes this DashboardMetric to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardMetricCopyWith<DashboardMetric> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardMetricCopyWith<$Res> {
  factory $DashboardMetricCopyWith(
    DashboardMetric value,
    $Res Function(DashboardMetric) then,
  ) = _$DashboardMetricCopyWithImpl<$Res, DashboardMetric>;
  @useResult
  $Res call({String label, String value, String unit, String icon});
}

/// @nodoc
class _$DashboardMetricCopyWithImpl<$Res, $Val extends DashboardMetric>
    implements $DashboardMetricCopyWith<$Res> {
  _$DashboardMetricCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? unit = null,
    Object? icon = null,
  }) {
    return _then(
      _value.copyWith(
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            unit: null == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String,
            icon: null == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardMetricImplCopyWith<$Res>
    implements $DashboardMetricCopyWith<$Res> {
  factory _$$DashboardMetricImplCopyWith(
    _$DashboardMetricImpl value,
    $Res Function(_$DashboardMetricImpl) then,
  ) = __$$DashboardMetricImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String label, String value, String unit, String icon});
}

/// @nodoc
class __$$DashboardMetricImplCopyWithImpl<$Res>
    extends _$DashboardMetricCopyWithImpl<$Res, _$DashboardMetricImpl>
    implements _$$DashboardMetricImplCopyWith<$Res> {
  __$$DashboardMetricImplCopyWithImpl(
    _$DashboardMetricImpl _value,
    $Res Function(_$DashboardMetricImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? unit = null,
    Object? icon = null,
  }) {
    return _then(
      _$DashboardMetricImpl(
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        unit: null == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardMetricImpl implements _DashboardMetric {
  const _$DashboardMetricImpl({
    required this.label,
    required this.value,
    this.unit = '',
    this.icon = '',
  });

  factory _$DashboardMetricImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardMetricImplFromJson(json);

  @override
  final String label;
  @override
  final String value;
  @override
  @JsonKey()
  final String unit;
  @override
  @JsonKey()
  final String icon;

  @override
  String toString() {
    return 'DashboardMetric(label: $label, value: $value, unit: $unit, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardMetricImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, label, value, unit, icon);

  /// Create a copy of DashboardMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardMetricImplCopyWith<_$DashboardMetricImpl> get copyWith =>
      __$$DashboardMetricImplCopyWithImpl<_$DashboardMetricImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardMetricImplToJson(this);
  }
}

abstract class _DashboardMetric implements DashboardMetric {
  const factory _DashboardMetric({
    required final String label,
    required final String value,
    final String unit,
    final String icon,
  }) = _$DashboardMetricImpl;

  factory _DashboardMetric.fromJson(Map<String, dynamic> json) =
      _$DashboardMetricImpl.fromJson;

  @override
  String get label;
  @override
  String get value;
  @override
  String get unit;
  @override
  String get icon;

  /// Create a copy of DashboardMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardMetricImplCopyWith<_$DashboardMetricImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DashboardNotification _$DashboardNotificationFromJson(
  Map<String, dynamic> json,
) {
  return _DashboardNotification.fromJson(json);
}

/// @nodoc
mixin _$DashboardNotification {
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this DashboardNotification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DashboardNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DashboardNotificationCopyWith<DashboardNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DashboardNotificationCopyWith<$Res> {
  factory $DashboardNotificationCopyWith(
    DashboardNotification value,
    $Res Function(DashboardNotification) then,
  ) = _$DashboardNotificationCopyWithImpl<$Res, DashboardNotification>;
  @useResult
  $Res call({String title, String body, DateTime timestamp});
}

/// @nodoc
class _$DashboardNotificationCopyWithImpl<
  $Res,
  $Val extends DashboardNotification
>
    implements $DashboardNotificationCopyWith<$Res> {
  _$DashboardNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DashboardNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? body = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DashboardNotificationImplCopyWith<$Res>
    implements $DashboardNotificationCopyWith<$Res> {
  factory _$$DashboardNotificationImplCopyWith(
    _$DashboardNotificationImpl value,
    $Res Function(_$DashboardNotificationImpl) then,
  ) = __$$DashboardNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, String body, DateTime timestamp});
}

/// @nodoc
class __$$DashboardNotificationImplCopyWithImpl<$Res>
    extends
        _$DashboardNotificationCopyWithImpl<$Res, _$DashboardNotificationImpl>
    implements _$$DashboardNotificationImplCopyWith<$Res> {
  __$$DashboardNotificationImplCopyWithImpl(
    _$DashboardNotificationImpl _value,
    $Res Function(_$DashboardNotificationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DashboardNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? body = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$DashboardNotificationImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DashboardNotificationImpl implements _DashboardNotification {
  const _$DashboardNotificationImpl({
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory _$DashboardNotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$DashboardNotificationImplFromJson(json);

  @override
  final String title;
  @override
  final String body;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'DashboardNotification(title: $title, body: $body, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DashboardNotificationImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, body, timestamp);

  /// Create a copy of DashboardNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DashboardNotificationImplCopyWith<_$DashboardNotificationImpl>
  get copyWith =>
      __$$DashboardNotificationImplCopyWithImpl<_$DashboardNotificationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DashboardNotificationImplToJson(this);
  }
}

abstract class _DashboardNotification implements DashboardNotification {
  const factory _DashboardNotification({
    required final String title,
    required final String body,
    required final DateTime timestamp,
  }) = _$DashboardNotificationImpl;

  factory _DashboardNotification.fromJson(Map<String, dynamic> json) =
      _$DashboardNotificationImpl.fromJson;

  @override
  String get title;
  @override
  String get body;
  @override
  DateTime get timestamp;

  /// Create a copy of DashboardNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DashboardNotificationImplCopyWith<_$DashboardNotificationImpl>
  get copyWith => throw _privateConstructorUsedError;
}
