part of 'generated.dart';

class UpdateSkillVariablesBuilder {
  String id;
  String category;

  final FirebaseDataConnect _dataConnect;
  UpdateSkillVariablesBuilder(this._dataConnect, {required  this.id,required  this.category,});
  Deserializer<UpdateSkillData> dataDeserializer = (dynamic json)  => UpdateSkillData.fromJson(jsonDecode(json));
  Serializer<UpdateSkillVariables> varsSerializer = (UpdateSkillVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateSkillData, UpdateSkillVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateSkillData, UpdateSkillVariables> ref() {
    UpdateSkillVariables vars= UpdateSkillVariables(id: id,category: category,);
    return _dataConnect.mutation("UpdateSkill", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateSkillSkillUpdate {
  final String id;
  UpdateSkillSkillUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSkillSkillUpdate otherTyped = other as UpdateSkillSkillUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateSkillSkillUpdate({
    required this.id,
  });
}

@immutable
class UpdateSkillData {
  final UpdateSkillSkillUpdate? skill_update;
  UpdateSkillData.fromJson(dynamic json):
  
  skill_update = json['skill_update'] == null ? null : UpdateSkillSkillUpdate.fromJson(json['skill_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSkillData otherTyped = other as UpdateSkillData;
    return skill_update == otherTyped.skill_update;
    
  }
  @override
  int get hashCode => skill_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (skill_update != null) {
      json['skill_update'] = skill_update!.toJson();
    }
    return json;
  }

  UpdateSkillData({
    this.skill_update,
  });
}

@immutable
class UpdateSkillVariables {
  final String id;
  final String category;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateSkillVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  category = nativeFromJson<String>(json['category']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSkillVariables otherTyped = other as UpdateSkillVariables;
    return id == otherTyped.id && 
    category == otherTyped.category;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, category.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['category'] = nativeToJson<String>(category);
    return json;
  }

  UpdateSkillVariables({
    required this.id,
    required this.category,
  });
}

