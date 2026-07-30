part of 'generated.dart';

class UpdateMyUserVariablesBuilder {
  Optional<String> _displayName = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _bio = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  UpdateMyUserVariablesBuilder displayName(String? t) {
   _displayName.value = t;
   return this;
  }
  UpdateMyUserVariablesBuilder bio(String? t) {
   _bio.value = t;
   return this;
  }

  UpdateMyUserVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateMyUserData> dataDeserializer = (dynamic json)  => UpdateMyUserData.fromJson(jsonDecode(json));
  Serializer<UpdateMyUserVariables> varsSerializer = (UpdateMyUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateMyUserData, UpdateMyUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateMyUserData, UpdateMyUserVariables> ref() {
    UpdateMyUserVariables vars= UpdateMyUserVariables(displayName: _displayName,bio: _bio,);
    return _dataConnect.mutation("UpdateMyUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateMyUserUserUpdate {
  final String id;
  UpdateMyUserUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMyUserUserUpdate otherTyped = other as UpdateMyUserUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateMyUserUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateMyUserData {
  final UpdateMyUserUserUpdate? user_update;
  UpdateMyUserData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateMyUserUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMyUserData otherTyped = other as UpdateMyUserData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateMyUserData({
    this.user_update,
  });
}

@immutable
class UpdateMyUserVariables {
  late final Optional<String>displayName;
  late final Optional<String>bio;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateMyUserVariables.fromJson(Map<String, dynamic> json) {
  
  
    displayName = Optional.optional(nativeFromJson, nativeToJson);
    displayName.value = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']);
  
  
    bio = Optional.optional(nativeFromJson, nativeToJson);
    bio.value = json['bio'] == null ? null : nativeFromJson<String>(json['bio']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMyUserVariables otherTyped = other as UpdateMyUserVariables;
    return displayName == otherTyped.displayName && 
    bio == otherTyped.bio;
    
  }
  @override
  int get hashCode => Object.hashAll([displayName.hashCode, bio.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(displayName.state == OptionalState.set) {
      json['displayName'] = displayName.toJson();
    }
    if(bio.state == OptionalState.set) {
      json['bio'] = bio.toJson();
    }
    return json;
  }

  UpdateMyUserVariables({
    required this.displayName,
    required this.bio,
  });
}

