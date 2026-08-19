part of 'generated.dart';

class GetUserByIdVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetUserByIdVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetUserByIdData> dataDeserializer = (dynamic json)  => GetUserByIdData.fromJson(jsonDecode(json));
  Serializer<GetUserByIdVariables> varsSerializer = (GetUserByIdVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetUserByIdData, GetUserByIdVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetUserByIdData, GetUserByIdVariables> ref() {
    GetUserByIdVariables vars= GetUserByIdVariables(id: id,);
    return _dataConnect.query("GetUserById", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetUserByIdUser {
  final String id;
  final double dogeBalance;
  final double stakedBalance;
  final double bankBalance;
  final String role;
  final double petHunger;
  final double petHappiness;
  final double petEnergy;
  final double petTotalDistanceWalked;
  final Timestamp? lastClaimTime;
  GetUserByIdUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  dogeBalance = nativeFromJson<double>(json['dogeBalance']),
  stakedBalance = nativeFromJson<double>(json['stakedBalance']),
  bankBalance = nativeFromJson<double>(json['bankBalance']),
  role = nativeFromJson<String>(json['role']),
  petHunger = nativeFromJson<double>(json['petHunger']),
  petHappiness = nativeFromJson<double>(json['petHappiness']),
  petEnergy = nativeFromJson<double>(json['petEnergy']),
  petTotalDistanceWalked = nativeFromJson<double>(json['petTotalDistanceWalked']),
  lastClaimTime = json['lastClaimTime'] == null ? null : Timestamp.fromJson(json['lastClaimTime']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByIdUser otherTyped = other as GetUserByIdUser;
    return id == otherTyped.id && 
    dogeBalance == otherTyped.dogeBalance && 
    stakedBalance == otherTyped.stakedBalance && 
    bankBalance == otherTyped.bankBalance && 
    role == otherTyped.role && 
    petHunger == otherTyped.petHunger && 
    petHappiness == otherTyped.petHappiness && 
    petEnergy == otherTyped.petEnergy && 
    petTotalDistanceWalked == otherTyped.petTotalDistanceWalked && 
    lastClaimTime == otherTyped.lastClaimTime;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, dogeBalance.hashCode, stakedBalance.hashCode, bankBalance.hashCode, role.hashCode, petHunger.hashCode, petHappiness.hashCode, petEnergy.hashCode, petTotalDistanceWalked.hashCode, lastClaimTime.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['dogeBalance'] = nativeToJson<double>(dogeBalance);
    json['stakedBalance'] = nativeToJson<double>(stakedBalance);
    json['bankBalance'] = nativeToJson<double>(bankBalance);
    json['role'] = nativeToJson<String>(role);
    json['petHunger'] = nativeToJson<double>(petHunger);
    json['petHappiness'] = nativeToJson<double>(petHappiness);
    json['petEnergy'] = nativeToJson<double>(petEnergy);
    json['petTotalDistanceWalked'] = nativeToJson<double>(petTotalDistanceWalked);
    if (lastClaimTime != null) {
      json['lastClaimTime'] = lastClaimTime!.toJson();
    }
    return json;
  }

  GetUserByIdUser({
    required this.id,
    required this.dogeBalance,
    required this.stakedBalance,
    required this.bankBalance,
    required this.role,
    required this.petHunger,
    required this.petHappiness,
    required this.petEnergy,
    required this.petTotalDistanceWalked,
    this.lastClaimTime,
  });
}

@immutable
class GetUserByIdData {
  final GetUserByIdUser? user;
  GetUserByIdData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetUserByIdUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByIdData otherTyped = other as GetUserByIdData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetUserByIdData({
    this.user,
  });
}

@immutable
class GetUserByIdVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetUserByIdVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserByIdVariables otherTyped = other as GetUserByIdVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetUserByIdVariables({
    required this.id,
  });
}

