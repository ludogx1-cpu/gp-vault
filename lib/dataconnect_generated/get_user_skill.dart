part of 'generated.dart';

class GetUserSkillVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetUserSkillVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetUserSkillData> dataDeserializer = (dynamic json)  => GetUserSkillData.fromJson(jsonDecode(json));
  Serializer<GetUserSkillVariables> varsSerializer = (GetUserSkillVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetUserSkillData, GetUserSkillVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetUserSkillData, GetUserSkillVariables> ref() {
    GetUserSkillVariables vars= GetUserSkillVariables(id: id,);
    return _dataConnect.query("GetUserSkill", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetUserSkillUserSkill {
  final GetUserSkillUserSkillUser user;
  final GetUserSkillUserSkillSkill skill;
  final String level;
  GetUserSkillUserSkill.fromJson(dynamic json):
  
  user = GetUserSkillUserSkillUser.fromJson(json['user']),
  skill = GetUserSkillUserSkillSkill.fromJson(json['skill']),
  level = nativeFromJson<String>(json['level']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserSkillUserSkill otherTyped = other as GetUserSkillUserSkill;
    return user == otherTyped.user && 
    skill == otherTyped.skill && 
    level == otherTyped.level;
    
  }
  @override
  int get hashCode => Object.hashAll([user.hashCode, skill.hashCode, level.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user'] = user.toJson();
    json['skill'] = skill.toJson();
    json['level'] = nativeToJson<String>(level);
    return json;
  }

  GetUserSkillUserSkill({
    required this.user,
    required this.skill,
    required this.level,
  });
}

@immutable
class GetUserSkillUserSkillUser {
  final String displayName;
  GetUserSkillUserSkillUser.fromJson(dynamic json):
  
  displayName = nativeFromJson<String>(json['displayName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserSkillUserSkillUser otherTyped = other as GetUserSkillUserSkillUser;
    return displayName == otherTyped.displayName;
    
  }
  @override
  int get hashCode => displayName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    return json;
  }

  GetUserSkillUserSkillUser({
    required this.displayName,
  });
}

@immutable
class GetUserSkillUserSkillSkill {
  final String name;
  GetUserSkillUserSkillSkill.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserSkillUserSkillSkill otherTyped = other as GetUserSkillUserSkillSkill;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetUserSkillUserSkillSkill({
    required this.name,
  });
}

@immutable
class GetUserSkillData {
  final GetUserSkillUserSkill? userSkill;
  GetUserSkillData.fromJson(dynamic json):
  
  userSkill = json['userSkill'] == null ? null : GetUserSkillUserSkill.fromJson(json['userSkill']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserSkillData otherTyped = other as GetUserSkillData;
    return userSkill == otherTyped.userSkill;
    
  }
  @override
  int get hashCode => userSkill.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (userSkill != null) {
      json['userSkill'] = userSkill!.toJson();
    }
    return json;
  }

  GetUserSkillData({
    this.userSkill,
  });
}

@immutable
class GetUserSkillVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetUserSkillVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserSkillVariables otherTyped = other as GetUserSkillVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetUserSkillVariables({
    required this.id,
  });
}

