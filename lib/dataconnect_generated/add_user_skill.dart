part of 'generated.dart';

class AddUserSkillVariablesBuilder {
  String skillId;
  String level;

  final FirebaseDataConnect _dataConnect;
  AddUserSkillVariablesBuilder(this._dataConnect, {required  this.skillId,required  this.level,});
  Deserializer<AddUserSkillData> dataDeserializer = (dynamic json)  => AddUserSkillData.fromJson(jsonDecode(json));
  Serializer<AddUserSkillVariables> varsSerializer = (AddUserSkillVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<AddUserSkillData, AddUserSkillVariables>> execute() {
    return ref().execute();
  }

  MutationRef<AddUserSkillData, AddUserSkillVariables> ref() {
    AddUserSkillVariables vars= AddUserSkillVariables(skillId: skillId,level: level,);
    return _dataConnect.mutation("AddUserSkill", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class AddUserSkillUserSkillInsert {
  final String id;
  AddUserSkillUserSkillInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddUserSkillUserSkillInsert otherTyped = other as AddUserSkillUserSkillInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  AddUserSkillUserSkillInsert({
    required this.id,
  });
}

@immutable
class AddUserSkillData {
  final AddUserSkillUserSkillInsert userSkill_insert;
  AddUserSkillData.fromJson(dynamic json):
  
  userSkill_insert = AddUserSkillUserSkillInsert.fromJson(json['userSkill_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddUserSkillData otherTyped = other as AddUserSkillData;
    return userSkill_insert == otherTyped.userSkill_insert;
    
  }
  @override
  int get hashCode => userSkill_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userSkill_insert'] = userSkill_insert.toJson();
    return json;
  }

  AddUserSkillData({
    required this.userSkill_insert,
  });
}

@immutable
class AddUserSkillVariables {
  final String skillId;
  final String level;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  AddUserSkillVariables.fromJson(Map<String, dynamic> json):
  
  skillId = nativeFromJson<String>(json['skillId']),
  level = nativeFromJson<String>(json['level']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final AddUserSkillVariables otherTyped = other as AddUserSkillVariables;
    return skillId == otherTyped.skillId && 
    level == otherTyped.level;
    
  }
  @override
  int get hashCode => Object.hashAll([skillId.hashCode, level.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['skillId'] = nativeToJson<String>(skillId);
    json['level'] = nativeToJson<String>(level);
    return json;
  }

  AddUserSkillVariables({
    required this.skillId,
    required this.level,
  });
}

