part of 'generated.dart';

class ListReviewsForSessionVariablesBuilder {
  String sessionId;

  final FirebaseDataConnect _dataConnect;
  ListReviewsForSessionVariablesBuilder(this._dataConnect, {required  this.sessionId,});
  Deserializer<ListReviewsForSessionData> dataDeserializer = (dynamic json)  => ListReviewsForSessionData.fromJson(jsonDecode(json));
  Serializer<ListReviewsForSessionVariables> varsSerializer = (ListReviewsForSessionVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<ListReviewsForSessionData, ListReviewsForSessionVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListReviewsForSessionData, ListReviewsForSessionVariables> ref() {
    ListReviewsForSessionVariables vars= ListReviewsForSessionVariables(sessionId: sessionId,);
    return _dataConnect.query("ListReviewsForSession", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ListReviewsForSessionReviews {
  final int rating;
  final String comment;
  ListReviewsForSessionReviews.fromJson(dynamic json):
  
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

    final ListReviewsForSessionReviews otherTyped = other as ListReviewsForSessionReviews;
    return rating == otherTyped.rating && 
    comment == otherTyped.comment;
    
  }
  @override
  int get hashCode => Object.hashAll([rating.hashCode, comment.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['rating'] = nativeToJson<int>(rating);
    json['comment'] = nativeToJson<String>(comment);
    return json;
  }

  ListReviewsForSessionReviews({
    required this.rating,
    required this.comment,
  });
}

@immutable
class ListReviewsForSessionData {
  final List<ListReviewsForSessionReviews> reviews;
  ListReviewsForSessionData.fromJson(dynamic json):
  
  reviews = (json['reviews'] as List<dynamic>)
        .map((e) => ListReviewsForSessionReviews.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListReviewsForSessionData otherTyped = other as ListReviewsForSessionData;
    return reviews == otherTyped.reviews;
    
  }
  @override
  int get hashCode => reviews.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['reviews'] = reviews.map((e) => e.toJson()).toList();
    return json;
  }

  ListReviewsForSessionData({
    required this.reviews,
  });
}

@immutable
class ListReviewsForSessionVariables {
  final String sessionId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ListReviewsForSessionVariables.fromJson(Map<String, dynamic> json):
  
  sessionId = nativeFromJson<String>(json['sessionId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListReviewsForSessionVariables otherTyped = other as ListReviewsForSessionVariables;
    return sessionId == otherTyped.sessionId;
    
  }
  @override
  int get hashCode => sessionId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['sessionId'] = nativeToJson<String>(sessionId);
    return json;
  }

  ListReviewsForSessionVariables({
    required this.sessionId,
  });
}

