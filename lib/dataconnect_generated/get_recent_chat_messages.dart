part of 'generated.dart';

class GetRecentChatMessagesVariablesBuilder {
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetRecentChatMessagesVariablesBuilder limit(int? t) {
   _limit.value = t;
   return this;
  }

  GetRecentChatMessagesVariablesBuilder(this._dataConnect, );
  Deserializer<GetRecentChatMessagesData> dataDeserializer = (dynamic json)  => GetRecentChatMessagesData.fromJson(jsonDecode(json));
  Serializer<GetRecentChatMessagesVariables> varsSerializer = (GetRecentChatMessagesVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetRecentChatMessagesData, GetRecentChatMessagesVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetRecentChatMessagesData, GetRecentChatMessagesVariables> ref() {
    GetRecentChatMessagesVariables vars= GetRecentChatMessagesVariables(limit: _limit,);
    return _dataConnect.query("GetRecentChatMessages", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetRecentChatMessagesChatMessages {
  final String id;
  final String text;
  final Timestamp timestamp;
  final GetRecentChatMessagesChatMessagesUser user;
  GetRecentChatMessagesChatMessages.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  text = nativeFromJson<String>(json['text']),
  timestamp = Timestamp.fromJson(json['timestamp']),
  user = GetRecentChatMessagesChatMessagesUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentChatMessagesChatMessages otherTyped = other as GetRecentChatMessagesChatMessages;
    return id == otherTyped.id && 
    text == otherTyped.text && 
    timestamp == otherTyped.timestamp && 
    user == otherTyped.user;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, text.hashCode, timestamp.hashCode, user.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['text'] = nativeToJson<String>(text);
    json['timestamp'] = timestamp.toJson();
    json['user'] = user.toJson();
    return json;
  }

  GetRecentChatMessagesChatMessages({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.user,
  });
}

@immutable
class GetRecentChatMessagesChatMessagesUser {
  final String id;
  final String role;
  GetRecentChatMessagesChatMessagesUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  role = nativeFromJson<String>(json['role']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentChatMessagesChatMessagesUser otherTyped = other as GetRecentChatMessagesChatMessagesUser;
    return id == otherTyped.id && 
    role == otherTyped.role;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, role.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['role'] = nativeToJson<String>(role);
    return json;
  }

  GetRecentChatMessagesChatMessagesUser({
    required this.id,
    required this.role,
  });
}

@immutable
class GetRecentChatMessagesData {
  final List<GetRecentChatMessagesChatMessages> chatMessages;
  GetRecentChatMessagesData.fromJson(dynamic json):
  
  chatMessages = (json['chatMessages'] as List<dynamic>)
        .map((e) => GetRecentChatMessagesChatMessages.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentChatMessagesData otherTyped = other as GetRecentChatMessagesData;
    return chatMessages == otherTyped.chatMessages;
    
  }
  @override
  int get hashCode => chatMessages.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['chatMessages'] = chatMessages.map((e) => e.toJson()).toList();
    return json;
  }

  GetRecentChatMessagesData({
    required this.chatMessages,
  });
}

@immutable
class GetRecentChatMessagesVariables {
  late final Optional<int>limit;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetRecentChatMessagesVariables.fromJson(Map<String, dynamic> json) {
  
  
    limit = Optional.optional(nativeFromJson, nativeToJson);
    limit.value = json['limit'] == null ? null : nativeFromJson<int>(json['limit']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetRecentChatMessagesVariables otherTyped = other as GetRecentChatMessagesVariables;
    return limit == otherTyped.limit;
    
  }
  @override
  int get hashCode => limit.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(limit.state == OptionalState.set) {
      json['limit'] = limit.toJson();
    }
    return json;
  }

  GetRecentChatMessagesVariables({
    required this.limit,
  });
}

