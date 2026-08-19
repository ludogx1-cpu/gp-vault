part of 'generated.dart';

class GetAppUpdatesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetAppUpdatesVariablesBuilder(this._dataConnect, );
  Deserializer<GetAppUpdatesData> dataDeserializer = (dynamic json)  => GetAppUpdatesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetAppUpdatesData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAppUpdatesData, void> ref() {
    
    return _dataConnect.query("GetAppUpdates", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetAppUpdatesAppUpdates {
  final String id;
  final String title;
  final String content;
  final Timestamp timestamp;
  GetAppUpdatesAppUpdates.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  title = nativeFromJson<String>(json['title']),
  content = nativeFromJson<String>(json['content']),
  timestamp = Timestamp.fromJson(json['timestamp']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAppUpdatesAppUpdates otherTyped = other as GetAppUpdatesAppUpdates;
    return id == otherTyped.id && 
    title == otherTyped.title && 
    content == otherTyped.content && 
    timestamp == otherTyped.timestamp;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, title.hashCode, content.hashCode, timestamp.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['content'] = nativeToJson<String>(content);
    json['timestamp'] = timestamp.toJson();
    return json;
  }

  GetAppUpdatesAppUpdates({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
  });
}

@immutable
class GetAppUpdatesData {
  final List<GetAppUpdatesAppUpdates> appUpdates;
  GetAppUpdatesData.fromJson(dynamic json):
  
  appUpdates = (json['appUpdates'] as List<dynamic>)
        .map((e) => GetAppUpdatesAppUpdates.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAppUpdatesData otherTyped = other as GetAppUpdatesData;
    return appUpdates == otherTyped.appUpdates;
    
  }
  @override
  int get hashCode => appUpdates.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['appUpdates'] = appUpdates.map((e) => e.toJson()).toList();
    return json;
  }

  GetAppUpdatesData({
    required this.appUpdates,
  });
}

