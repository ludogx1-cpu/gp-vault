part of 'generated.dart';

class GetReviewVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetReviewVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetReviewData> dataDeserializer = (dynamic json)  => GetReviewData.fromJson(jsonDecode(json));
  Serializer<GetReviewVariables> varsSerializer = (GetReviewVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetReviewData, GetReviewVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetReviewData, GetReviewVariables> ref() {
    GetReviewVariables vars= GetReviewVariables(id: id,);
    return _dataConnect.query("GetReview", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetReviewReview {
  final int rating;
  final String comment;
  final GetReviewReviewReviewer reviewer;
  GetReviewReview.fromJson(dynamic json):
  
  rating = nativeFromJson<int>(json['rating']),
  comment = nativeFromJson<String>(json['comment']),
  reviewer = GetReviewReviewReviewer.fromJson(json['reviewer']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetReviewReview otherTyped = other as GetReviewReview;
    return rating == otherTyped.rating && 
    comment == otherTyped.comment && 
    reviewer == otherTyped.reviewer;
    
  }
  @override
  int get hashCode => Object.hashAll([rating.hashCode, comment.hashCode, reviewer.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['rating'] = nativeToJson<int>(rating);
    json['comment'] = nativeToJson<String>(comment);
    json['reviewer'] = reviewer.toJson();
    return json;
  }

  GetReviewReview({
    required this.rating,
    required this.comment,
    required this.reviewer,
  });
}

@immutable
class GetReviewReviewReviewer {
  final String displayName;
  GetReviewReviewReviewer.fromJson(dynamic json):
  
  displayName = nativeFromJson<String>(json['displayName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetReviewReviewReviewer otherTyped = other as GetReviewReviewReviewer;
    return displayName == otherTyped.displayName;
    
  }
  @override
  int get hashCode => displayName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    return json;
  }

  GetReviewReviewReviewer({
    required this.displayName,
  });
}

@immutable
class GetReviewData {
  final GetReviewReview? review;
  GetReviewData.fromJson(dynamic json):
  
  review = json['review'] == null ? null : GetReviewReview.fromJson(json['review']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetReviewData otherTyped = other as GetReviewData;
    return review == otherTyped.review;
    
  }
  @override
  int get hashCode => review.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (review != null) {
      json['review'] = review!.toJson();
    }
    return json;
  }

  GetReviewData({
    this.review,
  });
}

@immutable
class GetReviewVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetReviewVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetReviewVariables otherTyped = other as GetReviewVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetReviewVariables({
    required this.id,
  });
}

