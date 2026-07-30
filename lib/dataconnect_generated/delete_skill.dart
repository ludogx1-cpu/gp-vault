part of 'generated.dart';

class DeleteSkillVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteSkillVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteSkillData> dataDeserializer = (dynamic json)  => DeleteSkillData.fromJson(jsonDecode(json));
  Serializer<DeleteSkillVariables> varsSerializer = (DeleteSkillVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteSkillData, DeleteSkillVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteSkillData, DeleteSkillVariables> ref() {
    DeleteSkillVariables vars= DeleteSkillVariables(id: id,);
    return _dataConnect.mutation("DeleteSkill", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteSkillSkillDelete {
  final String id;
  DeleteSkillSkillDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSkillSkillDelete otherTyped = other as DeleteSkillSkillDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSkillSkillDelete({
    required this.id,
  });
}

@immutable
class DeleteSkillData {
  final DeleteSkillSkillDelete? skill_delete;
  DeleteSkillData.fromJson(dynamic json):
  
  skill_delete = json['skill_delete'] == null ? null : DeleteSkillSkillDelete.fromJson(json['skill_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSkillData otherTyped = other as DeleteSkillData;
    return skill_delete == otherTyped.skill_delete;
    
  }
  @override
  int get hashCode => skill_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (skill_delete != null) {
      json['skill_delete'] = skill_delete!.toJson();
    }
    return json;
  }

  DeleteSkillData({
    this.skill_delete,
  });
}

@immutable
class DeleteSkillVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteSkillVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSkillVariables otherTyped = other as DeleteSkillVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSkillVariables({
    required this.id,
  });
}

