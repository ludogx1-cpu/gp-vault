part of 'generated.dart';

class SendChatMessageVariablesBuilder {
  String userId;
  String text;

  final FirebaseDataConnect _dataConnect;
  SendChatMessageVariablesBuilder(this._dataConnect, {required  this.userId,required  this.text,});
  Deserializer<SendChatMessageData> dataDeserializer = (dynamic json)  => SendChatMessageData.fromJson(jsonDecode(json));
  Serializer<SendChatMessageVariables> varsSerializer = (SendChatMessageVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<SendChatMessageData, SendChatMessageVariables>> execute() {
    return ref().execute();
  }

  MutationRef<SendChatMessageData, SendChatMessageVariables> ref() {
    SendChatMessageVariables vars= SendChatMessageVariables(userId: userId,text: text,);
    return _dataConnect.mutation("SendChatMessage", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class SendChatMessageChatMessageInsert {
  final String id;
  SendChatMessageChatMessageInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SendChatMessageChatMessageInsert otherTyped = other as SendChatMessageChatMessageInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  SendChatMessageChatMessageInsert({
    required this.id,
  });
}

@immutable
class SendChatMessageData {
  final SendChatMessageChatMessageInsert chatMessage_insert;
  SendChatMessageData.fromJson(dynamic json):
  
  chatMessage_insert = SendChatMessageChatMessageInsert.fromJson(json['chatMessage_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SendChatMessageData otherTyped = other as SendChatMessageData;
    return chatMessage_insert == otherTyped.chatMessage_insert;
    
  }
  @override
  int get hashCode => chatMessage_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['chatMessage_insert'] = chatMessage_insert.toJson();
    return json;
  }

  SendChatMessageData({
    required this.chatMessage_insert,
  });
}

@immutable
class SendChatMessageVariables {
  final String userId;
  final String text;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  SendChatMessageVariables.fromJson(Map<String, dynamic> json):
  
  userId = nativeFromJson<String>(json['userId']),
  text = nativeFromJson<String>(json['text']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SendChatMessageVariables otherTyped = other as SendChatMessageVariables;
    return userId == otherTyped.userId && 
    text == otherTyped.text;
    
  }
  @override
  int get hashCode => Object.hashAll([userId.hashCode, text.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['userId'] = nativeToJson<String>(userId);
    json['text'] = nativeToJson<String>(text);
    return json;
  }

  SendChatMessageVariables({
    required this.userId,
    required this.text,
  });
}

