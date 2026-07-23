// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MedicalHistoryImpl _$$MedicalHistoryImplFromJson(Map<String, dynamic> json) =>
    _$MedicalHistoryImpl(
      records: (json['records'] as List<dynamic>)
          .map((e) => MedicalRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MedicalHistoryImplToJson(
  _$MedicalHistoryImpl instance,
) => <String, dynamic>{'records': instance.records};

_$MedicalRecordImpl _$$MedicalRecordImplFromJson(Map<String, dynamic> json) =>
    _$MedicalRecordImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      documentUrl: json['documentUrl'] as String? ?? '',
    );

Map<String, dynamic> _$$MedicalRecordImplToJson(_$MedicalRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'date': instance.date.toIso8601String(),
      'documentUrl': instance.documentUrl,
    };
