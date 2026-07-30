part of 'generated.dart';

class DeleteMyUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  DeleteMyUserVariablesBuilder(this._dataConnect, );
  Deserializer<DeleteMyUserData> dataDeserializer = (dynamic json)  => DeleteMyUserData.fromJson(jsonDecode(json));
  
  Future<OperationResult<DeleteMyUserData, void>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteMyUserData, void> ref() {
    
    return _dataConnect.mutation("DeleteMyUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class DeleteMyUserUserDelete {
  final String id;
  DeleteMyUserUserDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteMyUserUserDelete otherTyped = other as DeleteMyUserUserDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteMyUserUserDelete({
    required this.id,
  });
}

@immutable
class DeleteMyUserData {
  final DeleteMyUserUserDelete? user_delete;
  DeleteMyUserData.fromJson(dynamic json):
  
  user_delete = json['user_delete'] == null ? null : DeleteMyUserUserDelete.fromJson(json['user_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteMyUserData otherTyped = other as DeleteMyUserData;
    return user_delete == otherTyped.user_delete;
    
  }
  @override
  int get hashCode => user_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_delete != null) {
      json['user_delete'] = user_delete!.toJson();
    }
    return json;
  }

  DeleteMyUserData({
    this.user_delete,
  });
}

