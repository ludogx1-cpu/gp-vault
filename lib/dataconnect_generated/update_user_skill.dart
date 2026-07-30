part of 'generated.dart';

class UpdateUserSkillVariablesBuilder {
  String id;
  String level;

  final FirebaseDataConnect _dataConnect;
  UpdateUserSkillVariablesBuilder(this._dataConnect, {required  this.id,required  this.level,});
  Deserializer<UpdateUserSkillData> dataDeserializer = (dynamic json)  => UpdateUserSkillData.fromJson(jsonDecode(json));
  Serializer<UpdateUserSkillVariables> varsSerializer = (UpdateUserSkillVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateUserSkillData, UpdateUserSkillVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateUserSkillData, UpdateUserSkillVariables> ref() {
    UpdateUserSkillVariables vars= UpdateUserSkillVariables(id: id,level: level,);
    return _dataConnect.mutation("UpdateUserSkill", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateUserSkillUserSkillUpdate {
  final String id;
  UpdateUserSkillUserSkillUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserSkillUserSkillUpdate otherTyped = other as UpdateUserSkillUserSkillUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateUserSkillUserSkillUpdate({
    required this.id,
  });
}

@immutable
class UpdateUserSkillData {
  final UpdateUserSkillUserSkillUpdate? userSkill_update;
  UpdateUserSkillData.fromJson(dynamic json):
  
  userSkill_update = json['userSkill_update'] == null ? null : UpdateUserSkillUserSkillUpdate.fromJson(json['userSkill_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserSkillData otherTyped = other as UpdateUserSkillData;
    return userSkill_update == otherTyped.userSkill_update;
    
  }
  @override
  int get hashCode => userSkill_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (userSkill_update != null) {
      json['userSkill_update'] = userSkill_update!.toJson();
    }
    return json;
  }

  UpdateUserSkillData({
    this.userSkill_update,
  });
}

@immutable
class UpdateUserSkillVariables {
  final String id;
  final String level;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateUserSkillVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  level = nativeFromJson<String>(json['level']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserSkillVariables otherTyped = other as UpdateUserSkillVariables;
    return id == otherTyped.id && 
    level == otherTyped.level;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, level.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['level'] = nativeToJson<String>(level);
    return json;
  }

  UpdateUserSkillVariables({
    required this.id,
    required this.level,
  });
}

