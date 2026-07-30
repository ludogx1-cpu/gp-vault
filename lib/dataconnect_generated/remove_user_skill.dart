part of 'generated.dart';

class RemoveUserSkillVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  RemoveUserSkillVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<RemoveUserSkillData> dataDeserializer = (dynamic json)  => RemoveUserSkillData.fromJson(jsonDecode(json));
  Serializer<RemoveUserSkillVariables> varsSerializer = (RemoveUserSkillVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<RemoveUserSkillData, RemoveUserSkillVariables>> execute() {
    return ref().execute();
  }

  MutationRef<RemoveUserSkillData, RemoveUserSkillVariables> ref() {
    RemoveUserSkillVariables vars= RemoveUserSkillVariables(id: id,);
    return _dataConnect.mutation("RemoveUserSkill", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class RemoveUserSkillUserSkillDelete {
  final String id;
  RemoveUserSkillUserSkillDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveUserSkillUserSkillDelete otherTyped = other as RemoveUserSkillUserSkillDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RemoveUserSkillUserSkillDelete({
    required this.id,
  });
}

@immutable
class RemoveUserSkillData {
  final RemoveUserSkillUserSkillDelete? userSkill_delete;
  RemoveUserSkillData.fromJson(dynamic json):
  
  userSkill_delete = json['userSkill_delete'] == null ? null : RemoveUserSkillUserSkillDelete.fromJson(json['userSkill_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveUserSkillData otherTyped = other as RemoveUserSkillData;
    return userSkill_delete == otherTyped.userSkill_delete;
    
  }
  @override
  int get hashCode => userSkill_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (userSkill_delete != null) {
      json['userSkill_delete'] = userSkill_delete!.toJson();
    }
    return json;
  }

  RemoveUserSkillData({
    this.userSkill_delete,
  });
}

@immutable
class RemoveUserSkillVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  RemoveUserSkillVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RemoveUserSkillVariables otherTyped = other as RemoveUserSkillVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RemoveUserSkillVariables({
    required this.id,
  });
}

