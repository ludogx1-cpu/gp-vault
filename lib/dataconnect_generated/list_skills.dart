part of 'generated.dart';

class ListSkillsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListSkillsVariablesBuilder(this._dataConnect, );
  Deserializer<ListSkillsData> dataDeserializer = (dynamic json)  => ListSkillsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListSkillsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListSkillsData, void> ref() {
    
    return _dataConnect.query("ListSkills", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListSkillsSkills {
  final String name;
  ListSkillsSkills.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSkillsSkills otherTyped = other as ListSkillsSkills;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ListSkillsSkills({
    required this.name,
  });
}

@immutable
class ListSkillsData {
  final List<ListSkillsSkills> skills;
  ListSkillsData.fromJson(dynamic json):
  
  skills = (json['skills'] as List<dynamic>)
        .map((e) => ListSkillsSkills.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSkillsData otherTyped = other as ListSkillsData;
    return skills == otherTyped.skills;
    
  }
  @override
  int get hashCode => skills.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['skills'] = skills.map((e) => e.toJson()).toList();
    return json;
  }

  ListSkillsData({
    required this.skills,
  });
}

