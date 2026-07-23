// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medical_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MedicalHistory _$MedicalHistoryFromJson(Map<String, dynamic> json) {
  return _MedicalHistory.fromJson(json);
}

/// @nodoc
mixin _$MedicalHistory {
  List<MedicalRecord> get records => throw _privateConstructorUsedError;

  /// Serializes this MedicalHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MedicalHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MedicalHistoryCopyWith<MedicalHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicalHistoryCopyWith<$Res> {
  factory $MedicalHistoryCopyWith(
    MedicalHistory value,
    $Res Function(MedicalHistory) then,
  ) = _$MedicalHistoryCopyWithImpl<$Res, MedicalHistory>;
  @useResult
  $Res call({List<MedicalRecord> records});
}

/// @nodoc
class _$MedicalHistoryCopyWithImpl<$Res, $Val extends MedicalHistory>
    implements $MedicalHistoryCopyWith<$Res> {
  _$MedicalHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MedicalHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? records = null}) {
    return _then(
      _value.copyWith(
            records: null == records
                ? _value.records
                : records // ignore: cast_nullable_to_non_nullable
                      as List<MedicalRecord>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MedicalHistoryImplCopyWith<$Res>
    implements $MedicalHistoryCopyWith<$Res> {
  factory _$$MedicalHistoryImplCopyWith(
    _$MedicalHistoryImpl value,
    $Res Function(_$MedicalHistoryImpl) then,
  ) = __$$MedicalHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MedicalRecord> records});
}

/// @nodoc
class __$$MedicalHistoryImplCopyWithImpl<$Res>
    extends _$MedicalHistoryCopyWithImpl<$Res, _$MedicalHistoryImpl>
    implements _$$MedicalHistoryImplCopyWith<$Res> {
  __$$MedicalHistoryImplCopyWithImpl(
    _$MedicalHistoryImpl _value,
    $Res Function(_$MedicalHistoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MedicalHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? records = null}) {
    return _then(
      _$MedicalHistoryImpl(
        records: null == records
            ? _value._records
            : records // ignore: cast_nullable_to_non_nullable
                  as List<MedicalRecord>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MedicalHistoryImpl implements _MedicalHistory {
  const _$MedicalHistoryImpl({required final List<MedicalRecord> records})
    : _records = records;

  factory _$MedicalHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MedicalHistoryImplFromJson(json);

  final List<MedicalRecord> _records;
  @override
  List<MedicalRecord> get records {
    if (_records is EqualUnmodifiableListView) return _records;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_records);
  }

  @override
  String toString() {
    return 'MedicalHistory(records: $records)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicalHistoryImpl &&
            const DeepCollectionEquality().equals(other._records, _records));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_records));

  /// Create a copy of MedicalHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicalHistoryImplCopyWith<_$MedicalHistoryImpl> get copyWith =>
      __$$MedicalHistoryImplCopyWithImpl<_$MedicalHistoryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MedicalHistoryImplToJson(this);
  }
}

abstract class _MedicalHistory implements MedicalHistory {
  const factory _MedicalHistory({required final List<MedicalRecord> records}) =
      _$MedicalHistoryImpl;

  factory _MedicalHistory.fromJson(Map<String, dynamic> json) =
      _$MedicalHistoryImpl.fromJson;

  @override
  List<MedicalRecord> get records;

  /// Create a copy of MedicalHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MedicalHistoryImplCopyWith<_$MedicalHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MedicalRecord _$MedicalRecordFromJson(Map<String, dynamic> json) {
  return _MedicalRecord.fromJson(json);
}

/// @nodoc
mixin _$MedicalRecord {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get documentUrl => throw _privateConstructorUsedError;

  /// Serializes this MedicalRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MedicalRecordCopyWith<MedicalRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicalRecordCopyWith<$Res> {
  factory $MedicalRecordCopyWith(
    MedicalRecord value,
    $Res Function(MedicalRecord) then,
  ) = _$MedicalRecordCopyWithImpl<$Res, MedicalRecord>;
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    DateTime date,
    String documentUrl,
  });
}

/// @nodoc
class _$MedicalRecordCopyWithImpl<$Res, $Val extends MedicalRecord>
    implements $MedicalRecordCopyWith<$Res> {
  _$MedicalRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? date = null,
    Object? documentUrl = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            documentUrl: null == documentUrl
                ? _value.documentUrl
                : documentUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MedicalRecordImplCopyWith<$Res>
    implements $MedicalRecordCopyWith<$Res> {
  factory _$$MedicalRecordImplCopyWith(
    _$MedicalRecordImpl value,
    $Res Function(_$MedicalRecordImpl) then,
  ) = __$$MedicalRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    DateTime date,
    String documentUrl,
  });
}

/// @nodoc
class __$$MedicalRecordImplCopyWithImpl<$Res>
    extends _$MedicalRecordCopyWithImpl<$Res, _$MedicalRecordImpl>
    implements _$$MedicalRecordImplCopyWith<$Res> {
  __$$MedicalRecordImplCopyWithImpl(
    _$MedicalRecordImpl _value,
    $Res Function(_$MedicalRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? date = null,
    Object? documentUrl = null,
  }) {
    return _then(
      _$MedicalRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        documentUrl: null == documentUrl
            ? _value.documentUrl
            : documentUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MedicalRecordImpl implements _MedicalRecord {
  const _$MedicalRecordImpl({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.documentUrl = '',
  });

  factory _$MedicalRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$MedicalRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final DateTime date;
  @override
  @JsonKey()
  final String documentUrl;

  @override
  String toString() {
    return 'MedicalRecord(id: $id, title: $title, description: $description, date: $date, documentUrl: $documentUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicalRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.documentUrl, documentUrl) ||
                other.documentUrl == documentUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, description, date, documentUrl);

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicalRecordImplCopyWith<_$MedicalRecordImpl> get copyWith =>
      __$$MedicalRecordImplCopyWithImpl<_$MedicalRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MedicalRecordImplToJson(this);
  }
}

abstract class _MedicalRecord implements MedicalRecord {
  const factory _MedicalRecord({
    required final String id,
    required final String title,
    required final String description,
    required final DateTime date,
    final String documentUrl,
  }) = _$MedicalRecordImpl;

  factory _MedicalRecord.fromJson(Map<String, dynamic> json) =
      _$MedicalRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  DateTime get date;
  @override
  String get documentUrl;

  /// Create a copy of MedicalRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MedicalRecordImplCopyWith<_$MedicalRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
