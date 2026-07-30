part of 'generated.dart';

class UpdateSessionStatusVariablesBuilder {
  String id;
  String status;

  final FirebaseDataConnect _dataConnect;
  UpdateSessionStatusVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,});
  Deserializer<UpdateSessionStatusData> dataDeserializer = (dynamic json)  => UpdateSessionStatusData.fromJson(jsonDecode(json));
  Serializer<UpdateSessionStatusVariables> varsSerializer = (UpdateSessionStatusVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateSessionStatusData, UpdateSessionStatusVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateSessionStatusData, UpdateSessionStatusVariables> ref() {
    UpdateSessionStatusVariables vars= UpdateSessionStatusVariables(id: id,status: status,);
    return _dataConnect.mutation("UpdateSessionStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateSessionStatusSessionUpdate {
  final String id;
  UpdateSessionStatusSessionUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSessionStatusSessionUpdate otherTyped = other as UpdateSessionStatusSessionUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateSessionStatusSessionUpdate({
    required this.id,
  });
}

@immutable
class UpdateSessionStatusData {
  final UpdateSessionStatusSessionUpdate? session_update;
  UpdateSessionStatusData.fromJson(dynamic json):
  
  session_update = json['session_update'] == null ? null : UpdateSessionStatusSessionUpdate.fromJson(json['session_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSessionStatusData otherTyped = other as UpdateSessionStatusData;
    return session_update == otherTyped.session_update;
    
  }
  @override
  int get hashCode => session_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (session_update != null) {
      json['session_update'] = session_update!.toJson();
    }
    return json;
  }

  UpdateSessionStatusData({
    this.session_update,
  });
}

@immutable
class UpdateSessionStatusVariables {
  final String id;
  final String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateSessionStatusVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSessionStatusVariables otherTyped = other as UpdateSessionStatusVariables;
    return id == otherTyped.id && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  UpdateSessionStatusVariables({
    required this.id,
    required this.status,
  });
}

