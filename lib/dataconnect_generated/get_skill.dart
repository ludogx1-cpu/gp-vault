part of 'generated.dart';

class GetSkillVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetSkillVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetSkillData> dataDeserializer = (dynamic json)  => GetSkillData.fromJson(jsonDecode(json));
  Serializer<GetSkillVariables> varsSerializer = (GetSkillVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSkillData, GetSkillVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetSkillData, GetSkillVariables> ref() {
    GetSkillVariables vars= GetSkillVariables(id: id,);
    return _dataConnect.query("GetSkill", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSkillSkill {
  final String name;
  final String category;
  GetSkillSkill.fromJson(dynamic json):
  
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

    final GetSkillSkill otherTyped = other as GetSkillSkill;
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

  GetSkillSkill({
    required this.name,
    required this.category,
  });
}

@immutable
class GetSkillData {
  final GetSkillSkill? skill;
  GetSkillData.fromJson(dynamic json):
  
  skill = json['skill'] == null ? null : GetSkillSkill.fromJson(json['skill']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSkillData otherTyped = other as GetSkillData;
    return skill == otherTyped.skill;
    
  }
  @override
  int get hashCode => skill.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (skill != null) {
      json['skill'] = skill!.toJson();
    }
    return json;
  }

  GetSkillData({
    this.skill,
  });
}

@immutable
class GetSkillVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSkillVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSkillVariables otherTyped = other as GetSkillVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetSkillVariables({
    required this.id,
  });
}

