part of 'generated.dart';

class CreateUserAccountVariablesBuilder {
  String displayName;
  String email;
  String bio;

  final FirebaseDataConnect _dataConnect;
  CreateUserAccountVariablesBuilder(this._dataConnect, {required  this.displayName,required  this.email,required  this.bio,});
  Deserializer<CreateUserAccountData> dataDeserializer = (dynamic json)  => CreateUserAccountData.fromJson(jsonDecode(json));
  Serializer<CreateUserAccountVariables> varsSerializer = (CreateUserAccountVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateUserAccountData, CreateUserAccountVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateUserAccountData, CreateUserAccountVariables> ref() {
    CreateUserAccountVariables vars= CreateUserAccountVariables(displayName: displayName,email: email,bio: bio,);
    return _dataConnect.mutation("CreateUserAccount", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateUserAccountUserInsert {
  final String id;
  CreateUserAccountUserInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserAccountUserInsert otherTyped = other as CreateUserAccountUserInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateUserAccountUserInsert({
    required this.id,
  });
}

@immutable
class CreateUserAccountData {
  final CreateUserAccountUserInsert user_insert;
  CreateUserAccountData.fromJson(dynamic json):
  
  user_insert = CreateUserAccountUserInsert.fromJson(json['user_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserAccountData otherTyped = other as CreateUserAccountData;
    return user_insert == otherTyped.user_insert;
    
  }
  @override
  int get hashCode => user_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    return json;
  }

  CreateUserAccountData({
    required this.user_insert,
  });
}

@immutable
class CreateUserAccountVariables {
  final String displayName;
  final String email;
  final String bio;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateUserAccountVariables.fromJson(Map<String, dynamic> json):
  
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

    final CreateUserAccountVariables otherTyped = other as CreateUserAccountVariables;
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

  CreateUserAccountVariables({
    required this.displayName,
    required this.email,
    required this.bio,
  });
}

