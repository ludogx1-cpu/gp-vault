part of 'generated.dart';

class ListMySkillsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMySkillsVariablesBuilder(this._dataConnect, );
  Deserializer<ListMySkillsData> dataDeserializer = (dynamic json)  => ListMySkillsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMySkillsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListMySkillsData, void> ref() {
    
    return _dataConnect.query("ListMySkills", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMySkillsUserSkills {
  final ListMySkillsUserSkillsSkill skill;
  final String level;
  ListMySkillsUserSkills.fromJson(dynamic json):
  
  skill = ListMySkillsUserSkillsSkill.fromJson(json['skill']),
  level = nativeFromJson<String>(json['level']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMySkillsUserSkills otherTyped = other as ListMySkillsUserSkills;
    return skill == otherTyped.skill && 
    level == otherTyped.level;
    
  }
  @override
  int get hashCode => Object.hashAll([skill.hashCode, level.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['skill'] = skill.toJson();
    json['level'] = nativeToJson<String>(level);
    return json;
  }

  ListMySkillsUserSkills({
    required this.skill,
    required this.level,
  });
}

@immutable
class ListMySkillsUserSkillsSkill {
  final String name;
  ListMySkillsUserSkillsSkill.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMySkillsUserSkillsSkill otherTyped = other as ListMySkillsUserSkillsSkill;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ListMySkillsUserSkillsSkill({
    required this.name,
  });
}

@immutable
class ListMySkillsData {
  final List<ListMySkillsUserSkills> userSkills;
  ListMySkillsData.fromJson(dynamic json):
  
  userSkills = (json['userSkills'] as List<dynamic>)
        .map((e) => ListMySkillsUserSkills.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMySkillsData otherTyped = other as ListMySkillsData;
    return userSkills == otherTyped.userSkills;
    
  }
  @override
  int get hashCode => userSkills.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userSkills'] = userSkills.map((e) => e.toJson()).toList();
    return json;
  }

  ListMySkillsData({
    required this.userSkills,
  });
}

