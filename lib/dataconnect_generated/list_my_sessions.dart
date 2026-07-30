part of 'generated.dart';

class ListMySessionsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMySessionsVariablesBuilder(this._dataConnect, );
  Deserializer<ListMySessionsData> dataDeserializer = (dynamic json)  => ListMySessionsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMySessionsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListMySessionsData, void> ref() {
    
    return _dataConnect.query("ListMySessions", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMySessionsSessions {
  final String status;
  final Timestamp scheduledDate;
  ListMySessionsSessions.fromJson(dynamic json):
  
  status = nativeFromJson<String>(json['status']),
  scheduledDate = Timestamp.fromJson(json['scheduledDate']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMySessionsSessions otherTyped = other as ListMySessionsSessions;
    return status == otherTyped.status && 
    scheduledDate == otherTyped.scheduledDate;
    
  }
  @override
  int get hashCode => Object.hashAll([status.hashCode, scheduledDate.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['status'] = nativeToJson<String>(status);
    json['scheduledDate'] = scheduledDate.toJson();
    return json;
  }

  ListMySessionsSessions({
    required this.status,
    required this.scheduledDate,
  });
}

@immutable
class ListMySessionsData {
  final List<ListMySessionsSessions> sessions;
  ListMySessionsData.fromJson(dynamic json):
  
  sessions = (json['sessions'] as List<dynamic>)
        .map((e) => ListMySessionsSessions.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMySessionsData otherTyped = other as ListMySessionsData;
    return sessions == otherTyped.sessions;
    
  }
  @override
  int get hashCode => sessions.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['sessions'] = sessions.map((e) => e.toJson()).toList();
    return json;
  }

  ListMySessionsData({
    required this.sessions,
  });
}

