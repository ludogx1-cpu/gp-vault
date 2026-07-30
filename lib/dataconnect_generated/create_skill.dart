part of 'generated.dart';

class CreateSkillVariablesBuilder {
  String name;
  String category;

  final FirebaseDataConnect _dataConnect;
  CreateSkillVariablesBuilder(this._dataConnect, {required  this.name,required  this.category,});
  Deserializer<CreateSkillData> dataDeserializer = (dynamic json)  => CreateSkillData.fromJson(jsonDecode(json));
  Serializer<CreateSkillVariables> varsSerializer = (CreateSkillVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateSkillData, CreateSkillVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateSkillData, CreateSkillVariables> ref() {
    CreateSkillVariables vars= CreateSkillVariables(name: name,category: category,);
    return _dataConnect.mutation("CreateSkill", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateSkillSkillInsert {
  final String id;
  CreateSkillSkillInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSkillSkillInsert otherTyped = other as CreateSkillSkillInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateSkillSkillInsert({
    required this.id,
  });
}

@immutable
class CreateSkillData {
  final CreateSkillSkillInsert skill_insert;
  CreateSkillData.fromJson(dynamic json):
  
  skill_insert = CreateSkillSkillInsert.fromJson(json['skill_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSkillData otherTyped = other as CreateSkillData;
    return skill_insert == otherTyped.skill_insert;
    
  }
  @override
  int get hashCode => skill_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['skill_insert'] = skill_insert.toJson();
    return json;
  }

  CreateSkillData({
    required this.skill_insert,
  });
}

@immutable
class CreateSkillVariables {
  final String name;
  final String category;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateSkillVariables.fromJson(Map<String, dynamic> json):
  
  name = nativeFromJson<String>(json['name']),
  category = nativeFromJson<String>(json['category']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSkillVariables otherTyped = other as CreateSkillVariables;
    return name == otherTyped.name && 
    category == otherTyped.category;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, category.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['category'] = nativeToJson<String>(category);
    return json;
  }

  CreateSkillVariables({
    required this.name,
    required this.category,
  });
}

