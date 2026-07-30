part of 'generated.dart';

class DeleteReviewVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteReviewVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteReviewData> dataDeserializer = (dynamic json)  => DeleteReviewData.fromJson(jsonDecode(json));
  Serializer<DeleteReviewVariables> varsSerializer = (DeleteReviewVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteReviewData, DeleteReviewVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteReviewData, DeleteReviewVariables> ref() {
    DeleteReviewVariables vars= DeleteReviewVariables(id: id,);
    return _dataConnect.mutation("DeleteReview", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteReviewReviewDelete {
  final String id;
  DeleteReviewReviewDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteReviewReviewDelete otherTyped = other as DeleteReviewReviewDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteReviewReviewDelete({
    required this.id,
  });
}

@immutable
class DeleteReviewData {
  final DeleteReviewReviewDelete? review_delete;
  DeleteReviewData.fromJson(dynamic json):
  
  review_delete = json['review_delete'] == null ? null : DeleteReviewReviewDelete.fromJson(json['review_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteReviewData otherTyped = other as DeleteReviewData;
    return review_delete == otherTyped.review_delete;
    
  }
  @override
  int get hashCode => review_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (review_delete != null) {
      json['review_delete'] = review_delete!.toJson();
    }
    return json;
  }

  DeleteReviewData({
    this.review_delete,
  });
}

@immutable
class DeleteReviewVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteReviewVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteReviewVariables otherTyped = other as DeleteReviewVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteReviewVariables({
    required this.id,
  });
}

