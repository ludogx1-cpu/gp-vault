part of 'generated.dart';

class ProposeSessionVariablesBuilder {
  String recipientId;
  Timestamp scheduledDate;

  final FirebaseDataConnect _dataConnect;
  ProposeSessionVariablesBuilder(this._dataConnect, {required  this.recipientId,required  this.scheduledDate,});
  Deserializer<ProposeSessionData> dataDeserializer = (dynamic json)  => ProposeSessionData.fromJson(jsonDecode(json));
  Serializer<ProposeSessionVariables> varsSerializer = (ProposeSessionVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ProposeSessionData, ProposeSessionVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ProposeSessionData, ProposeSessionVariables> ref() {
    ProposeSessionVariables vars= ProposeSessionVariables(recipientId: recipientId,scheduledDate: scheduledDate,);
    return _dataConnect.mutation("ProposeSession", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ProposeSessionSessionInsert {
  final String id;
  ProposeSessionSessionInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ProposeSessionSessionInsert otherTyped = other as ProposeSessionSessionInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ProposeSessionSessionInsert({
    required this.id,
  });
}

@immutable
class ProposeSessionData {
  final ProposeSessionSessionInsert session_insert;
  ProposeSessionData.fromJson(dynamic json):
  
  session_insert = ProposeSessionSessionInsert.fromJson(json['session_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ProposeSessionData otherTyped = other as ProposeSessionData;
    return session_insert == otherTyped.session_insert;
    
  }
  @override
  int get hashCode => session_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['session_insert'] = session_insert.toJson();
    return json;
  }

  ProposeSessionData({
    required this.session_insert,
  });
}

@immutable
class ProposeSessionVariables {
  final String recipientId;
  final Timestamp scheduledDate;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ProposeSessionVariables.fromJson(Map<String, dynamic> json):
  
  recipientId = nativeFromJson<String>(json['recipientId']),
  scheduledDate = Timestamp.fromJson(json['scheduledDate']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ProposeSessionVariables otherTyped = other as ProposeSessionVariables;
    return recipientId == otherTyped.recipientId && 
    scheduledDate == otherTyped.scheduledDate;
    
  }
  @override
  int get hashCode => Object.hashAll([recipientId.hashCode, scheduledDate.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['recipientId'] = nativeToJson<String>(recipientId);
    json['scheduledDate'] = scheduledDate.toJson();
    return json;
  }

  ProposeSessionVariables({
    required this.recipientId,
    required this.scheduledDate,
  });
}

