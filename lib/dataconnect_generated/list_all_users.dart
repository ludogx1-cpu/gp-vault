part of 'generated.dart';

class ListAllUsersVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListAllUsersVariablesBuilder(this._dataConnect, );
  Deserializer<ListAllUsersData> dataDeserializer = (dynamic json)  => ListAllUsersData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListAllUsersData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListAllUsersData, void> ref() {
    
    return _dataConnect.query("ListAllUsers", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListAllUsersUsers {
  final String displayName;
  final String bio;
  ListAllUsersUsers.fromJson(dynamic json):
  
  displayName = nativeFromJson<String>(json['displayName']),
  bio = nativeFromJson<String>(json['bio']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllUsersUsers otherTyped = other as ListAllUsersUsers;
    return displayName == otherTyped.displayName && 
    bio == otherTyped.bio;
    
  }
  @override
  int get hashCode => Object.hashAll([displayName.hashCode, bio.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    json['bio'] = nativeToJson<String>(bio);
    return json;
  }

  ListAllUsersUsers({
    required this.displayName,
    required this.bio,
  });
}

@immutable
class ListAllUsersData {
  final List<ListAllUsersUsers> users;
  ListAllUsersData.fromJson(dynamic json):
  
  users = (json['users'] as List<dynamic>)
        .map((e) => ListAllUsersUsers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListAllUsersData otherTyped = other as ListAllUsersData;
    return users == otherTyped.users;
    
  }
  @override
  int get hashCode => users.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['users'] = users.map((e) => e.toJson()).toList();
    return json;
  }

  ListAllUsersData({
    required this.users,
  });
}

