part of 'generated.dart';

class GetSessionVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetSessionVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetSessionData> dataDeserializer = (dynamic json)  => GetSessionData.fromJson(jsonDecode(json));
  Serializer<GetSessionVariables> varsSerializer = (GetSessionVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSessionData, GetSessionVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetSessionData, GetSessionVariables> ref() {
    GetSessionVariables vars= GetSessionVariables(id: id,);
    return _dataConnect.query("GetSession", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSessionSession {
  final String status;
  final Timestamp scheduledDate;
  final GetSessionSessionProposer proposer;
  GetSessionSession.fromJson(dynamic json):
  
  status = nativeFromJson<String>(json['status']),
  scheduledDate = Timestamp.fromJson(json['scheduledDate']),
  proposer = GetSessionSessionProposer.fromJson(json['proposer']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSessionSession otherTyped = other as GetSessionSession;
    return status == otherTyped.status && 
    scheduledDate == otherTyped.scheduledDate && 
    proposer == otherTyped.proposer;
    
  }
  @override
  int get hashCode => Object.hashAll([status.hashCode, scheduledDate.hashCode, proposer.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['status'] = nativeToJson<String>(status);
    json['scheduledDate'] = scheduledDate.toJson();
    json['proposer'] = proposer.toJson();
    return json;
  }

  GetSessionSession({
    required this.status,
    required this.scheduledDate,
    required this.proposer,
  });
}

@immutable
class GetSessionSessionProposer {
  final String displayName;
  GetSessionSessionProposer.fromJson(dynamic json):
  
  displayName = nativeFromJson<String>(json['displayName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSessionSessionProposer otherTyped = other as GetSessionSessionProposer;
    return displayName == otherTyped.displayName;
    
  }
  @override
  int get hashCode => displayName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    return json;
  }

  GetSessionSessionProposer({
    required this.displayName,
  });
}

@immutable
class GetSessionData {
  final GetSessionSession? session;
  GetSessionData.fromJson(dynamic json):
  
  session = json['session'] == null ? null : GetSessionSession.fromJson(json['session']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSessionData otherTyped = other as GetSessionData;
    return session == otherTyped.session;
    
  }
  @override
  int get hashCode => session.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (session != null) {
      json['session'] = session!.toJson();
    }
    return json;
  }

  GetSessionData({
    this.session,
  });
}

@immutable
class GetSessionVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSessionVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSessionVariables otherTyped = other as GetSessionVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetSessionVariables({
    required this.id,
  });
}

