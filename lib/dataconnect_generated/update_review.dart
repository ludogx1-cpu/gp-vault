part of 'generated.dart';

class UpdateReviewVariablesBuilder {
  String id;
  int rating;
  String comment;

  final FirebaseDataConnect _dataConnect;
  UpdateReviewVariablesBuilder(this._dataConnect, {required  this.id,required  this.rating,required  this.comment,});
  Deserializer<UpdateReviewData> dataDeserializer = (dynamic json)  => UpdateReviewData.fromJson(jsonDecode(json));
  Serializer<UpdateReviewVariables> varsSerializer = (UpdateReviewVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateReviewData, UpdateReviewVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateReviewData, UpdateReviewVariables> ref() {
    UpdateReviewVariables vars= UpdateReviewVariables(id: id,rating: rating,comment: comment,);
    return _dataConnect.mutation("UpdateReview", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateReviewReviewUpdate {
  final String id;
  UpdateReviewReviewUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReviewReviewUpdate otherTyped = other as UpdateReviewReviewUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateReviewReviewUpdate({
    required this.id,
  });
}

@immutable
class UpdateReviewData {
  final UpdateReviewReviewUpdate? review_update;
  UpdateReviewData.fromJson(dynamic json):
  
  review_update = json['review_update'] == null ? null : UpdateReviewReviewUpdate.fromJson(json['review_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReviewData otherTyped = other as UpdateReviewData;
    return review_update == otherTyped.review_update;
    
  }
  @override
  int get hashCode => review_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (review_update != null) {
      json['review_update'] = review_update!.toJson();
    }
    return json;
  }

  UpdateReviewData({
    this.review_update,
  });
}

@immutable
class UpdateReviewVariables {
  final String id;
  final int rating;
  final String comment;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateReviewVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  rating = nativeFromJson<int>(json['rating']),
  comment = nativeFromJson<String>(json['comment']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReviewVariables otherTyped = other as UpdateReviewVariables;
    return id == otherTyped.id && 
    rating == otherTyped.rating && 
    comment == otherTyped.comment;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, rating.hashCode, comment.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['rating'] = nativeToJson<int>(rating);
    json['comment'] = nativeToJson<String>(comment);
    return json;
  }

  UpdateReviewVariables({
    required this.id,
    required this.rating,
    required this.comment,
  });
}

