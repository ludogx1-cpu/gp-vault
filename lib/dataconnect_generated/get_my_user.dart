part of 'generated.dart';

class GetMyUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMyUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyUserData> dataDeserializer = (dynamic json)  => GetMyUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMyUserData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetMyUserData, void> ref() {
    
    return _dataConnect.query("GetMyUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMyUserUser {
  final String displayName;
  final String email;
  final String bio;
  GetMyUserUser.fromJson(dynamic json):
  
  displayName = nativeFromJson<String>(json['displayName']),
  email = nativeFromJson<String>(json['email']),
  bio = nativeFromJson<String>(json['bio']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyUserUser otherTyped = other as GetMyUserUser;
    return displayName == otherTyped.displayName && 
    email == otherTyped.email && 
    bio == otherTyped.bio;
    
  }
  @override
  int get hashCode => Object.hashAll([displayName.hashCode, email.hashCode, bio.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    json['email'] = nativeToJson<String>(email);
    json['bio'] = nativeToJson<String>(bio);
    return json;
  }

  GetMyUserUser({
    required this.displayName,
    required this.email,
    required this.bio,
  });
}

@immutable
class GetMyUserData {
  final GetMyUserUser? user;
  GetMyUserData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetMyUserUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyUserData otherTyped = other as GetMyUserData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetMyUserData({
    this.user,
  });
}

