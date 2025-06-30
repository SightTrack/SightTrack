/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:collection/collection.dart';


/** This is an auto generated class representing the Report type in your schema. */
class Report extends amplify_core.Model {
  static const classType = const _ReportModelType();
  final String id;
  final amplify_core.TemporalDateTime? _timestamp;
  final Sighting? _reportedSighting;
  final User? _reporter;
  final List<String>? _reasons;
  final String? _reasonsString;
  final ReportStatus? _status;
  final String? _adminNotes;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;
  final String? _reportReportedSightingId;
  final String? _reportReporterId;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ReportModelIdentifier get modelIdentifier {
      return ReportModelIdentifier(
        id: id
      );
  }
  
  amplify_core.TemporalDateTime get timestamp {
    try {
      return _timestamp!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  Sighting? get reportedSighting {
    return _reportedSighting;
  }
  
  User? get reporter {
    return _reporter;
  }
  
  List<String> get reasons {
    try {
      return _reasons!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get reasonsString {
    try {
      return _reasonsString!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  ReportStatus get status {
    try {
      return _status!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get adminNotes {
    return _adminNotes;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  String? get reportReportedSightingId {
    return _reportReportedSightingId;
  }
  
  String? get reportReporterId {
    return _reportReporterId;
  }
  
  const Report._internal({required this.id, required timestamp, reportedSighting, reporter, required reasons, required reasonsString, required status, adminNotes, createdAt, updatedAt, reportReportedSightingId, reportReporterId}): _timestamp = timestamp, _reportedSighting = reportedSighting, _reporter = reporter, _reasons = reasons, _reasonsString = reasonsString, _status = status, _adminNotes = adminNotes, _createdAt = createdAt, _updatedAt = updatedAt, _reportReportedSightingId = reportReportedSightingId, _reportReporterId = reportReporterId;
  
  factory Report({String? id, required amplify_core.TemporalDateTime timestamp, Sighting? reportedSighting, User? reporter, required List<String> reasons, required String reasonsString, required ReportStatus status, String? adminNotes, String? reportReportedSightingId, String? reportReporterId}) {
    return Report._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      timestamp: timestamp,
      reportedSighting: reportedSighting,
      reporter: reporter,
      reasons: reasons != null ? List<String>.unmodifiable(reasons) : reasons,
      reasonsString: reasonsString,
      status: status,
      adminNotes: adminNotes,
      reportReportedSightingId: reportReportedSightingId,
      reportReporterId: reportReporterId);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Report &&
      id == other.id &&
      _timestamp == other._timestamp &&
      _reportedSighting == other._reportedSighting &&
      _reporter == other._reporter &&
      DeepCollectionEquality().equals(_reasons, other._reasons) &&
      _reasonsString == other._reasonsString &&
      _status == other._status &&
      _adminNotes == other._adminNotes &&
      _reportReportedSightingId == other._reportReportedSightingId &&
      _reportReporterId == other._reportReporterId;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Report {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("timestamp=" + (_timestamp != null ? _timestamp!.format() : "null") + ", ");
    buffer.write("reasons=" + (_reasons != null ? _reasons!.toString() : "null") + ", ");
    buffer.write("reasonsString=" + "$_reasonsString" + ", ");
    buffer.write("status=" + (_status != null ? amplify_core.enumToString(_status)! : "null") + ", ");
    buffer.write("adminNotes=" + "$_adminNotes" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null") + ", ");
    buffer.write("reportReportedSightingId=" + "$_reportReportedSightingId" + ", ");
    buffer.write("reportReporterId=" + "$_reportReporterId");
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Report copyWith({amplify_core.TemporalDateTime? timestamp, Sighting? reportedSighting, User? reporter, List<String>? reasons, String? reasonsString, ReportStatus? status, String? adminNotes, String? reportReportedSightingId, String? reportReporterId}) {
    return Report._internal(
      id: id,
      timestamp: timestamp ?? this.timestamp,
      reportedSighting: reportedSighting ?? this.reportedSighting,
      reporter: reporter ?? this.reporter,
      reasons: reasons ?? this.reasons,
      reasonsString: reasonsString ?? this.reasonsString,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      reportReportedSightingId: reportReportedSightingId ?? this.reportReportedSightingId,
      reportReporterId: reportReporterId ?? this.reportReporterId);
  }
  
  Report copyWithModelFieldValues({
    ModelFieldValue<amplify_core.TemporalDateTime>? timestamp,
    ModelFieldValue<Sighting?>? reportedSighting,
    ModelFieldValue<User?>? reporter,
    ModelFieldValue<List<String>?>? reasons,
    ModelFieldValue<String>? reasonsString,
    ModelFieldValue<ReportStatus>? status,
    ModelFieldValue<String?>? adminNotes,
    ModelFieldValue<String?>? reportReportedSightingId,
    ModelFieldValue<String?>? reportReporterId
  }) {
    return Report._internal(
      id: id,
      timestamp: timestamp == null ? this.timestamp : timestamp.value,
      reportedSighting: reportedSighting == null ? this.reportedSighting : reportedSighting.value,
      reporter: reporter == null ? this.reporter : reporter.value,
      reasons: reasons == null ? this.reasons : reasons.value,
      reasonsString: reasonsString == null ? this.reasonsString : reasonsString.value,
      status: status == null ? this.status : status.value,
      adminNotes: adminNotes == null ? this.adminNotes : adminNotes.value,
      reportReportedSightingId: reportReportedSightingId == null ? this.reportReportedSightingId : reportReportedSightingId.value,
      reportReporterId: reportReporterId == null ? this.reportReporterId : reportReporterId.value
    );
  }
  
  Report.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _timestamp = json['timestamp'] != null ? amplify_core.TemporalDateTime.fromString(json['timestamp']) : null,
      _reportedSighting = json['reportedSighting'] != null
        ? json['reportedSighting']['serializedData'] != null
          ? Sighting.fromJson(new Map<String, dynamic>.from(json['reportedSighting']['serializedData']))
          : Sighting.fromJson(new Map<String, dynamic>.from(json['reportedSighting']))
        : null,
      _reporter = json['reporter'] != null
        ? json['reporter']['serializedData'] != null
          ? User.fromJson(new Map<String, dynamic>.from(json['reporter']['serializedData']))
          : User.fromJson(new Map<String, dynamic>.from(json['reporter']))
        : null,
      _reasons = json['reasons']?.cast<String>(),
      _reasonsString = json['reasonsString'],
      _status = amplify_core.enumFromString<ReportStatus>(json['status'], ReportStatus.values),
      _adminNotes = json['adminNotes'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null,
      _reportReportedSightingId = json['reportReportedSightingId'],
      _reportReporterId = json['reportReporterId'];
  
  Map<String, dynamic> toJson() => {
    'id': id, 'timestamp': _timestamp?.format(), 'reportedSighting': _reportedSighting?.toJson(), 'reporter': _reporter?.toJson(), 'reasons': _reasons, 'reasonsString': _reasonsString, 'status': amplify_core.enumToString(_status), 'adminNotes': _adminNotes, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format(), 'reportReportedSightingId': _reportReportedSightingId, 'reportReporterId': _reportReporterId
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'timestamp': _timestamp,
    'reportedSighting': _reportedSighting,
    'reporter': _reporter,
    'reasons': _reasons,
    'reasonsString': _reasonsString,
    'status': _status,
    'adminNotes': _adminNotes,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
    'reportReportedSightingId': _reportReportedSightingId,
    'reportReporterId': _reportReporterId
  };

  static final amplify_core.QueryModelIdentifier<ReportModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ReportModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final TIMESTAMP = amplify_core.QueryField(fieldName: "timestamp");
  static final REPORTEDSIGHTING = amplify_core.QueryField(
    fieldName: "reportedSighting",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Sighting'));
  static final REPORTER = amplify_core.QueryField(
    fieldName: "reporter",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'User'));
  static final REASONS = amplify_core.QueryField(fieldName: "reasons");
  static final REASONSSTRING = amplify_core.QueryField(fieldName: "reasonsString");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final ADMINNOTES = amplify_core.QueryField(fieldName: "adminNotes");
  static final REPORTREPORTEDSIGHTINGID = amplify_core.QueryField(fieldName: "reportReportedSightingId");
  static final REPORTREPORTERID = amplify_core.QueryField(fieldName: "reportReporterId");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Report";
    modelSchemaDefinition.pluralName = "Reports";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.TIMESTAMP,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasOne(
      key: Report.REPORTEDSIGHTING,
      isRequired: false,
      ofModelName: 'Sighting',
      associatedKey: Sighting.ID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasOne(
      key: Report.REPORTER,
      isRequired: false,
      ofModelName: 'User',
      associatedKey: User.ID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.REASONS,
      isRequired: true,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.REASONSSTRING,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.STATUS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.enumeration)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.ADMINNOTES,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.REPORTREPORTEDSIGHTINGID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Report.REPORTREPORTERID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
  });
}

class _ReportModelType extends amplify_core.ModelType<Report> {
  const _ReportModelType();
  
  @override
  Report fromJson(Map<String, dynamic> jsonData) {
    return Report.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Report';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Report] in your schema.
 */
class ReportModelIdentifier implements amplify_core.ModelIdentifier<Report> {
  final String id;

  /** Create an instance of ReportModelIdentifier using [id] the primary key. */
  const ReportModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'ReportModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ReportModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}