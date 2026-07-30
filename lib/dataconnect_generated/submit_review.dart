part of 'generated.dart';

class SubmitReviewVariablesBuilder {
  String sessionId;
  int rating;
  String comment;

  final FirebaseDataConnect _dataConnect;
  SubmitReviewVariablesBuilder(this._dataConnect, {required  this.sessionId,required  this.rating,required  this.comment,});
  Deserializer<SubmitReviewData> dataDeserializer = (dynamic json)  => SubmitReviewData.fromJson(jsonDecode(json));
  Serializer<SubmitReviewVariables> varsSerializer = (SubmitReviewVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<SubmitReviewData, SubmitReviewVariables>> execute() {
    return ref().execute();
  }

  MutationRef<SubmitReviewData, SubmitReviewVariables> ref() {
    SubmitReviewVariables vars= SubmitReviewVariables(sessionId: sessionId,rating: rating,comment: comment,);
    return _dataConnect.mutation("SubmitReview", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class SubmitReviewReviewInsert {
  final String id;
  SubmitReviewReviewInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SubmitReviewReviewInsert otherTyped = other as SubmitReviewReviewInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  SubmitReviewReviewInsert({
    required this.id,
  });
}

@immutable
class SubmitReviewData {
  final SubmitReviewReviewInsert review_insert;
  SubmitReviewData.fromJson(dynamic json):
  
  review_insert = SubmitReviewReviewInsert.fromJson(json['review_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SubmitReviewData otherTyped = other as SubmitReviewData;
    return review_insert == otherTyped.review_insert;
    
  }
  @override
  int get hashCode => review_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['review_insert'] = review_insert.toJson();
    return json;
  }

  SubmitReviewData({
    required this.review_insert,
  });
}

@immutable
class SubmitReviewVariables {
  final String sessionId;
  final int rating;
  final String comment;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  SubmitReviewVariables.fromJson(Map<String, dynamic> json):
  
  sessionId = nativeFromJson<String>(json['sessionId']),
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

    final SubmitReviewVariables otherTyped = other as SubmitReviewVariables;
    return sessionId == otherTyped.sessionId && 
    rating == otherTyped.rating && 
    comment == otherTyped.comment;
    
  }
  @override
  int get hashCode => Object.hashAll([sessionId.hashCode, rating.hashCode, comment.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['sessionId'] = nativeToJson<String>(sessionId);
    json['rating'] = nativeToJson<int>(rating);
    json['comment'] = nativeToJson<String>(comment);
    return json;
  }

  SubmitReviewVariables({
    required this.sessionId,
    required this.rating,
    required this.comment,
  });
}

