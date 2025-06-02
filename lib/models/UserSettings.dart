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


/** This is an auto generated class representing the UserSettings type in your schema. */
class UserSettings extends amplify_core.Model {
  static const classType = const _UserSettingsModelType();
  final String id;
  final String? _userId;
  final bool? _locationOffset;
  final bool? _isAreaCaptureActive;
  final amplify_core.TemporalDateTime? _areaCaptureEnd;
  final List<String>? _activitySupervisor;
  final List<String>? _schoolSupervisor;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UserSettingsModelIdentifier get modelIdentifier {
      return UserSettingsModelIdentifier(
        id: id
      );
  }
  
  String get userId {
    try {
      return _userId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  bool? get locationOffset {
    return _locationOffset;
  }
  
  bool? get isAreaCaptureActive {
    return _isAreaCaptureActive;
  }
  
  amplify_core.TemporalDateTime? get areaCaptureEnd {
    return _areaCaptureEnd;
  }
  
  List<String>? get activitySupervisor {
    return _activitySupervisor;
  }
  
  List<String>? get schoolSupervisor {
    return _schoolSupervisor;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const UserSettings._internal({required this.id, required userId, locationOffset, isAreaCaptureActive, areaCaptureEnd, activitySupervisor, schoolSupervisor, createdAt, updatedAt}): _userId = userId, _locationOffset = locationOffset, _isAreaCaptureActive = isAreaCaptureActive, _areaCaptureEnd = areaCaptureEnd, _activitySupervisor = activitySupervisor, _schoolSupervisor = schoolSupervisor, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory UserSettings({String? id, required String userId, bool? locationOffset, bool? isAreaCaptureActive, amplify_core.TemporalDateTime? areaCaptureEnd, List<String>? activitySupervisor, List<String>? schoolSupervisor}) {
    return UserSettings._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      userId: userId,
      locationOffset: locationOffset,
      isAreaCaptureActive: isAreaCaptureActive,
      areaCaptureEnd: areaCaptureEnd,
      activitySupervisor: activitySupervisor != null ? List<String>.unmodifiable(activitySupervisor) : activitySupervisor,
      schoolSupervisor: schoolSupervisor != null ? List<String>.unmodifiable(schoolSupervisor) : schoolSupervisor);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserSettings &&
      id == other.id &&
      _userId == other._userId &&
      _locationOffset == other._locationOffset &&
      _isAreaCaptureActive == other._isAreaCaptureActive &&
      _areaCaptureEnd == other._areaCaptureEnd &&
      DeepCollectionEquality().equals(_activitySupervisor, other._activitySupervisor) &&
      DeepCollectionEquality().equals(_schoolSupervisor, other._schoolSupervisor);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UserSettings {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("userId=" + "$_userId" + ", ");
    buffer.write("locationOffset=" + (_locationOffset != null ? _locationOffset!.toString() : "null") + ", ");
    buffer.write("isAreaCaptureActive=" + (_isAreaCaptureActive != null ? _isAreaCaptureActive!.toString() : "null") + ", ");
    buffer.write("areaCaptureEnd=" + (_areaCaptureEnd != null ? _areaCaptureEnd!.format() : "null") + ", ");
    buffer.write("activitySupervisor=" + (_activitySupervisor != null ? _activitySupervisor!.toString() : "null") + ", ");
    buffer.write("schoolSupervisor=" + (_schoolSupervisor != null ? _schoolSupervisor!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UserSettings copyWith({String? userId, bool? locationOffset, bool? isAreaCaptureActive, amplify_core.TemporalDateTime? areaCaptureEnd, List<String>? activitySupervisor, List<String>? schoolSupervisor}) {
    return UserSettings._internal(
      id: id,
      userId: userId ?? this.userId,
      locationOffset: locationOffset ?? this.locationOffset,
      isAreaCaptureActive: isAreaCaptureActive ?? this.isAreaCaptureActive,
      areaCaptureEnd: areaCaptureEnd ?? this.areaCaptureEnd,
      activitySupervisor: activitySupervisor ?? this.activitySupervisor,
      schoolSupervisor: schoolSupervisor ?? this.schoolSupervisor);
  }
  
  UserSettings copyWithModelFieldValues({
    ModelFieldValue<String>? userId,
    ModelFieldValue<bool?>? locationOffset,
    ModelFieldValue<bool?>? isAreaCaptureActive,
    ModelFieldValue<amplify_core.TemporalDateTime?>? areaCaptureEnd,
    ModelFieldValue<List<String>?>? activitySupervisor,
    ModelFieldValue<List<String>?>? schoolSupervisor
  }) {
    return UserSettings._internal(
      id: id,
      userId: userId == null ? this.userId : userId.value,
      locationOffset: locationOffset == null ? this.locationOffset : locationOffset.value,
      isAreaCaptureActive: isAreaCaptureActive == null ? this.isAreaCaptureActive : isAreaCaptureActive.value,
      areaCaptureEnd: areaCaptureEnd == null ? this.areaCaptureEnd : areaCaptureEnd.value,
      activitySupervisor: activitySupervisor == null ? this.activitySupervisor : activitySupervisor.value,
      schoolSupervisor: schoolSupervisor == null ? this.schoolSupervisor : schoolSupervisor.value
    );
  }
  
  UserSettings.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _userId = json['userId'],
      _locationOffset = json['locationOffset'],
      _isAreaCaptureActive = json['isAreaCaptureActive'],
      _areaCaptureEnd = json['areaCaptureEnd'] != null ? amplify_core.TemporalDateTime.fromString(json['areaCaptureEnd']) : null,
      _activitySupervisor = json['activitySupervisor']?.cast<String>(),
      _schoolSupervisor = json['schoolSupervisor']?.cast<String>(),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'userId': _userId, 'locationOffset': _locationOffset, 'isAreaCaptureActive': _isAreaCaptureActive, 'areaCaptureEnd': _areaCaptureEnd?.format(), 'activitySupervisor': _activitySupervisor, 'schoolSupervisor': _schoolSupervisor, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'userId': _userId,
    'locationOffset': _locationOffset,
    'isAreaCaptureActive': _isAreaCaptureActive,
    'areaCaptureEnd': _areaCaptureEnd,
    'activitySupervisor': _activitySupervisor,
    'schoolSupervisor': _schoolSupervisor,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserSettingsModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserSettingsModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final USERID = amplify_core.QueryField(fieldName: "userId");
  static final LOCATIONOFFSET = amplify_core.QueryField(fieldName: "locationOffset");
  static final ISAREACAPTUREACTIVE = amplify_core.QueryField(fieldName: "isAreaCaptureActive");
  static final AREACAPTUREEND = amplify_core.QueryField(fieldName: "areaCaptureEnd");
  static final ACTIVITYSUPERVISOR = amplify_core.QueryField(fieldName: "activitySupervisor");
  static final SCHOOLSUPERVISOR = amplify_core.QueryField(fieldName: "schoolSupervisor");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "UserSettings";
    modelSchemaDefinition.pluralName = "UserSettings";
    
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
      key: UserSettings.USERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserSettings.LOCATIONOFFSET,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserSettings.ISAREACAPTUREACTIVE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserSettings.AREACAPTUREEND,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserSettings.ACTIVITYSUPERVISOR,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserSettings.SCHOOLSUPERVISOR,
      isRequired: false,
      isArray: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.collection, ofModelName: amplify_core.ModelFieldTypeEnum.string.name)
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
  });
}

class _UserSettingsModelType extends amplify_core.ModelType<UserSettings> {
  const _UserSettingsModelType();
  
  @override
  UserSettings fromJson(Map<String, dynamic> jsonData) {
    return UserSettings.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'UserSettings';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [UserSettings] in your schema.
 */
class UserSettingsModelIdentifier implements amplify_core.ModelIdentifier<UserSettings> {
  final String id;

  /** Create an instance of UserSettingsModelIdentifier using [id] the primary key. */
  const UserSettingsModelIdentifier({
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
  String toString() => 'UserSettingsModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserSettingsModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}