part of 'generated.dart';

class DeleteSessionVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteSessionVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteSessionData> dataDeserializer = (dynamic json)  => DeleteSessionData.fromJson(jsonDecode(json));
  Serializer<DeleteSessionVariables> varsSerializer = (DeleteSessionVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteSessionData, DeleteSessionVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteSessionData, DeleteSessionVariables> ref() {
    DeleteSessionVariables vars= DeleteSessionVariables(id: id,);
    return _dataConnect.mutation("DeleteSession", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteSessionSessionDelete {
  final String id;
  DeleteSessionSessionDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSessionSessionDelete otherTyped = other as DeleteSessionSessionDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSessionSessionDelete({
    required this.id,
  });
}

@immutable
class DeleteSessionData {
  final DeleteSessionSessionDelete? session_delete;
  DeleteSessionData.fromJson(dynamic json):
  
  session_delete = json['session_delete'] == null ? null : DeleteSessionSessionDelete.fromJson(json['session_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSessionData otherTyped = other as DeleteSessionData;
    return session_delete == otherTyped.session_delete;
    
  }
  @override
  int get hashCode => session_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (session_delete != null) {
      json['session_delete'] = session_delete!.toJson();
    }
    return json;
  }

  DeleteSessionData({
    this.session_delete,
  });
}

@immutable
class DeleteSessionVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteSessionVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSessionVariables otherTyped = other as DeleteSessionVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSessionVariables({
    required this.id,
  });
}

