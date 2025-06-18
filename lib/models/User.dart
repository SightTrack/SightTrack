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


/** This is an auto generated class representing the User type in your schema. */
class User extends amplify_core.Model {
  static const classType = const _UserModelType();
  final String id;
  final String? _display_username;
  final String? _email;
  final String? _profilePicture;
  final String? _bio;
  final String? _country;
  final List<Sighting>? _sightings;
  final UserSettings? _settings;
  final int? _age;
  final String? _school;
  final String? _realName;
  final String? _studentId;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;
  final String? _userSettingsId;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UserModelIdentifier get modelIdentifier {
      return UserModelIdentifier(
        id: id
      );
  }
  
  String get display_username {
    try {
      return _display_username!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get email {
    try {
      return _email!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get profilePicture {
    return _profilePicture;
  }
  
  String? get bio {
    return _bio;
  }
  
  String? get country {
    return _country;
  }
  
  List<Sighting>? get sightings {
    return _sightings;
  }
  
  UserSettings? get settings {
    return _settings;
  }
  
  int? get age {
    return _age;
  }
  
  String? get school {
    return _school;
  }
  
  String? get realName {
    return _realName;
  }
  
  String? get studentId {
    return _studentId;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  String? get userSettingsId {
    return _userSettingsId;
  }
  
  const User._internal({required this.id, required display_username, required email, profilePicture, bio, country, sightings, settings, age, school, realName, studentId, createdAt, updatedAt, userSettingsId}): _display_username = display_username, _email = email, _profilePicture = profilePicture, _bio = bio, _country = country, _sightings = sightings, _settings = settings, _age = age, _school = school, _realName = realName, _studentId = studentId, _createdAt = createdAt, _updatedAt = updatedAt, _userSettingsId = userSettingsId;
  
  factory User({String? id, required String display_username, required String email, String? profilePicture, String? bio, String? country, List<Sighting>? sightings, UserSettings? settings, int? age, String? school, String? realName, String? studentId, String? userSettingsId}) {
    return User._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      display_username: display_username,
      email: email,
      profilePicture: profilePicture,
      bio: bio,
      country: country,
      sightings: sightings != null ? List<Sighting>.unmodifiable(sightings) : sightings,
      settings: settings,
      age: age,
      school: school,
      realName: realName,
      studentId: studentId,
      userSettingsId: userSettingsId);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is User &&
      id == other.id &&
      _display_username == other._display_username &&
      _email == other._email &&
      _profilePicture == other._profilePicture &&
      _bio == other._bio &&
      _country == other._country &&
      DeepCollectionEquality().equals(_sightings, other._sightings) &&
      _settings == other._settings &&
      _age == other._age &&
      _school == other._school &&
      _realName == other._realName &&
      _studentId == other._studentId &&
      _userSettingsId == other._userSettingsId;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("User {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("display_username=" + "$_display_username" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("profilePicture=" + "$_profilePicture" + ", ");
    buffer.write("bio=" + "$_bio" + ", ");
    buffer.write("country=" + "$_country" + ", ");
    buffer.write("age=" + (_age != null ? _age!.toString() : "null") + ", ");
    buffer.write("school=" + "$_school" + ", ");
    buffer.write("realName=" + "$_realName" + ", ");
    buffer.write("studentId=" + "$_studentId" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null") + ", ");
    buffer.write("userSettingsId=" + "$_userSettingsId");
    buffer.write("}");
    
    return buffer.toString();
  }
  
  User copyWith({String? display_username, String? email, String? profilePicture, String? bio, String? country, List<Sighting>? sightings, UserSettings? settings, int? age, String? school, String? realName, String? studentId, String? userSettingsId}) {
    return User._internal(
      id: id,
      display_username: display_username ?? this.display_username,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      sightings: sightings ?? this.sightings,
      settings: settings ?? this.settings,
      age: age ?? this.age,
      school: school ?? this.school,
      realName: realName ?? this.realName,
      studentId: studentId ?? this.studentId,
      userSettingsId: userSettingsId ?? this.userSettingsId);
  }
  
  User copyWithModelFieldValues({
    ModelFieldValue<String>? display_username,
    ModelFieldValue<String>? email,
    ModelFieldValue<String?>? profilePicture,
    ModelFieldValue<String?>? bio,
    ModelFieldValue<String?>? country,
    ModelFieldValue<List<Sighting>?>? sightings,
    ModelFieldValue<UserSettings?>? settings,
    ModelFieldValue<int?>? age,
    ModelFieldValue<String?>? school,
    ModelFieldValue<String?>? realName,
    ModelFieldValue<String?>? studentId,
    ModelFieldValue<String?>? userSettingsId
  }) {
    return User._internal(
      id: id,
      display_username: display_username == null ? this.display_username : display_username.value,
      email: email == null ? this.email : email.value,
      profilePicture: profilePicture == null ? this.profilePicture : profilePicture.value,
      bio: bio == null ? this.bio : bio.value,
      country: country == null ? this.country : country.value,
      sightings: sightings == null ? this.sightings : sightings.value,
      settings: settings == null ? this.settings : settings.value,
      age: age == null ? this.age : age.value,
      school: school == null ? this.school : school.value,
      realName: realName == null ? this.realName : realName.value,
      studentId: studentId == null ? this.studentId : studentId.value,
      userSettingsId: userSettingsId == null ? this.userSettingsId : userSettingsId.value
    );
  }
  
  User.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _display_username = json['display_username'],
      _email = json['email'],
      _profilePicture = json['profilePicture'],
      _bio = json['bio'],
      _country = json['country'],
      _sightings = json['sightings']  is Map
        ? (json['sightings']['items'] is List
          ? (json['sightings']['items'] as List)
              .where((e) => e != null)
              .map((e) => Sighting.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['sightings'] is List
          ? (json['sightings'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Sighting.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _settings = json['settings'] != null
        ? json['settings']['serializedData'] != null
          ? UserSettings.fromJson(new Map<String, dynamic>.from(json['settings']['serializedData']))
          : UserSettings.fromJson(new Map<String, dynamic>.from(json['settings']))
        : null,
      _age = (json['age'] as num?)?.toInt(),
      _school = json['school'],
      _realName = json['realName'],
      _studentId = json['studentId'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null,
      _userSettingsId = json['userSettingsId'];
  
  Map<String, dynamic> toJson() => {
    'id': id, 'display_username': _display_username, 'email': _email, 'profilePicture': _profilePicture, 'bio': _bio, 'country': _country, 'sightings': _sightings?.map((Sighting? e) => e?.toJson()).toList(), 'settings': _settings?.toJson(), 'age': _age, 'school': _school, 'realName': _realName, 'studentId': _studentId, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format(), 'userSettingsId': _userSettingsId
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'display_username': _display_username,
    'email': _email,
    'profilePicture': _profilePicture,
    'bio': _bio,
    'country': _country,
    'sightings': _sightings,
    'settings': _settings,
    'age': _age,
    'school': _school,
    'realName': _realName,
    'studentId': _studentId,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt,
    'userSettingsId': _userSettingsId
  };

  static final amplify_core.QueryModelIdentifier<UserModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final DISPLAY_USERNAME = amplify_core.QueryField(fieldName: "display_username");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final PROFILEPICTURE = amplify_core.QueryField(fieldName: "profilePicture");
  static final BIO = amplify_core.QueryField(fieldName: "bio");
  static final COUNTRY = amplify_core.QueryField(fieldName: "country");
  static final SIGHTINGS = amplify_core.QueryField(
    fieldName: "sightings",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Sighting'));
  static final SETTINGS = amplify_core.QueryField(
    fieldName: "settings",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'UserSettings'));
  static final AGE = amplify_core.QueryField(fieldName: "age");
  static final SCHOOL = amplify_core.QueryField(fieldName: "school");
  static final REALNAME = amplify_core.QueryField(fieldName: "realName");
  static final STUDENTID = amplify_core.QueryField(fieldName: "studentId");
  static final USERSETTINGSID = amplify_core.QueryField(fieldName: "userSettingsId");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "User";
    modelSchemaDefinition.pluralName = "Users";
    
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
      key: User.DISPLAY_USERNAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.EMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.PROFILEPICTURE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.BIO,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.COUNTRY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: User.SIGHTINGS,
      isRequired: false,
      ofModelName: 'Sighting',
      associatedKey: Sighting.USER
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasOne(
      key: User.SETTINGS,
      isRequired: false,
      ofModelName: 'UserSettings',
      associatedKey: UserSettings.ID
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.AGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.SCHOOL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.REALNAME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.STUDENTID,
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
      key: User.USERSETTINGSID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
  });
}

class _UserModelType extends amplify_core.ModelType<User> {
  const _UserModelType();
  
  @override
  User fromJson(Map<String, dynamic> jsonData) {
    return User.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'User';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [User] in your schema.
 */
class UserModelIdentifier implements amplify_core.ModelIdentifier<User> {
  final String id;

  /** Create an instance of UserModelIdentifier using [id] the primary key. */
  const UserModelIdentifier({
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
  String toString() => 'UserModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}