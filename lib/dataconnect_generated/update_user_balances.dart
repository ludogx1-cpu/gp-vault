part of 'generated.dart';

class UpdateUserBalancesVariablesBuilder {
  String id;
  Optional<double> _dogeBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _stakedBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _bankBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _offerwallBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _adsBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _xp = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _totalClaims = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _faucetClaims = Optional.optional(nativeFromJson, nativeToJson);
  Optional<Timestamp> _lastClaimTime = Optional.optional((json) => json['lastClaimTime'] = Timestamp.fromJson(json['lastClaimTime']), defaultSerializer);

  final FirebaseDataConnect _dataConnect;  UpdateUserBalancesVariablesBuilder dogeBalance(double? t) {
   _dogeBalance.value = t;
   return this;
  }
  UpdateUserBalancesVariablesBuilder stakedBalance(double? t) {
   _stakedBalance.value = t;
   return this;
  }
  UpdateUserBalancesVariablesBuilder bankBalance(double? t) {
   _bankBalance.value = t;
   return this;
  }
  UpdateUserBalancesVariablesBuilder offerwallBalance(double? t) {
   _offerwallBalance.value = t;
   return this;
  }
  UpdateUserBalancesVariablesBuilder adsBalance(double? t) {
   _adsBalance.value = t;
   return this;
  }
  UpdateUserBalancesVariablesBuilder xp(int? t) {
   _xp.value = t;
   return this;
  }
  UpdateUserBalancesVariablesBuilder totalClaims(int? t) {
   _totalClaims.value = t;
   return this;
  }
  UpdateUserBalancesVariablesBuilder faucetClaims(int? t) {
   _faucetClaims.value = t;
   return this;
  }
  UpdateUserBalancesVariablesBuilder lastClaimTime(Timestamp? t) {
   _lastClaimTime.value = t;
   return this;
  }

  UpdateUserBalancesVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UpdateUserBalancesData> dataDeserializer = (dynamic json)  => UpdateUserBalancesData.fromJson(jsonDecode(json));
  Serializer<UpdateUserBalancesVariables> varsSerializer = (UpdateUserBalancesVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateUserBalancesData, UpdateUserBalancesVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateUserBalancesData, UpdateUserBalancesVariables> ref() {
    UpdateUserBalancesVariables vars= UpdateUserBalancesVariables(id: id,dogeBalance: _dogeBalance,stakedBalance: _stakedBalance,bankBalance: _bankBalance,offerwallBalance: _offerwallBalance,adsBalance: _adsBalance,xp: _xp,totalClaims: _totalClaims,faucetClaims: _faucetClaims,lastClaimTime: _lastClaimTime,);
    return _dataConnect.mutation("UpdateUserBalances", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateUserBalancesUserUpdate {
  final String id;
  UpdateUserBalancesUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserBalancesUserUpdate otherTyped = other as UpdateUserBalancesUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateUserBalancesUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateUserBalancesData {
  final UpdateUserBalancesUserUpdate? user_update;
  UpdateUserBalancesData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateUserBalancesUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserBalancesData otherTyped = other as UpdateUserBalancesData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateUserBalancesData({
    this.user_update,
  });
}

@immutable
class UpdateUserBalancesVariables {
  final String id;
  late final Optional<double>dogeBalance;
  late final Optional<double>stakedBalance;
  late final Optional<double>bankBalance;
  late final Optional<double>offerwallBalance;
  late final Optional<double>adsBalance;
  late final Optional<int>xp;
  late final Optional<int>totalClaims;
  late final Optional<int>faucetClaims;
  late final Optional<Timestamp>lastClaimTime;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateUserBalancesVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    dogeBalance = Optional.optional(nativeFromJson, nativeToJson);
    dogeBalance.value = json['dogeBalance'] == null ? null : nativeFromJson<double>(json['dogeBalance']);
  
  
    stakedBalance = Optional.optional(nativeFromJson, nativeToJson);
    stakedBalance.value = json['stakedBalance'] == null ? null : nativeFromJson<double>(json['stakedBalance']);
  
  
    bankBalance = Optional.optional(nativeFromJson, nativeToJson);
    bankBalance.value = json['bankBalance'] == null ? null : nativeFromJson<double>(json['bankBalance']);
  
  
    offerwallBalance = Optional.optional(nativeFromJson, nativeToJson);
    offerwallBalance.value = json['offerwallBalance'] == null ? null : nativeFromJson<double>(json['offerwallBalance']);
  
  
    adsBalance = Optional.optional(nativeFromJson, nativeToJson);
    adsBalance.value = json['adsBalance'] == null ? null : nativeFromJson<double>(json['adsBalance']);
  
  
    xp = Optional.optional(nativeFromJson, nativeToJson);
    xp.value = json['xp'] == null ? null : nativeFromJson<int>(json['xp']);
  
  
    totalClaims = Optional.optional(nativeFromJson, nativeToJson);
    totalClaims.value = json['totalClaims'] == null ? null : nativeFromJson<int>(json['totalClaims']);
  
  
    faucetClaims = Optional.optional(nativeFromJson, nativeToJson);
    faucetClaims.value = json['faucetClaims'] == null ? null : nativeFromJson<int>(json['faucetClaims']);
  
  
    lastClaimTime = Optional.optional((json) => json['lastClaimTime'] = Timestamp.fromJson(json['lastClaimTime']), defaultSerializer);
    lastClaimTime.value = json['lastClaimTime'] == null ? null : Timestamp.fromJson(json['lastClaimTime']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserBalancesVariables otherTyped = other as UpdateUserBalancesVariables;
    return id == otherTyped.id && 
    dogeBalance == otherTyped.dogeBalance && 
    stakedBalance == otherTyped.stakedBalance && 
    bankBalance == otherTyped.bankBalance && 
    offerwallBalance == otherTyped.offerwallBalance && 
    adsBalance == otherTyped.adsBalance && 
    xp == otherTyped.xp && 
    totalClaims == otherTyped.totalClaims && 
    faucetClaims == otherTyped.faucetClaims && 
    lastClaimTime == otherTyped.lastClaimTime;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, dogeBalance.hashCode, stakedBalance.hashCode, bankBalance.hashCode, offerwallBalance.hashCode, adsBalance.hashCode, xp.hashCode, totalClaims.hashCode, faucetClaims.hashCode, lastClaimTime.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(dogeBalance.state == OptionalState.set) {
      json['dogeBalance'] = dogeBalance.toJson();
    }
    if(stakedBalance.state == OptionalState.set) {
      json['stakedBalance'] = stakedBalance.toJson();
    }
    if(bankBalance.state == OptionalState.set) {
      json['bankBalance'] = bankBalance.toJson();
    }
    if(offerwallBalance.state == OptionalState.set) {
      json['offerwallBalance'] = offerwallBalance.toJson();
    }
    if(adsBalance.state == OptionalState.set) {
      json['adsBalance'] = adsBalance.toJson();
    }
    if(xp.state == OptionalState.set) {
      json['xp'] = xp.toJson();
    }
    if(totalClaims.state == OptionalState.set) {
      json['totalClaims'] = totalClaims.toJson();
    }
    if(faucetClaims.state == OptionalState.set) {
      json['faucetClaims'] = faucetClaims.toJson();
    }
    if(lastClaimTime.state == OptionalState.set) {
      json['lastClaimTime'] = lastClaimTime.toJson();
    }
    return json;
  }

  UpdateUserBalancesVariables({
    required this.id,
    required this.dogeBalance,
    required this.stakedBalance,
    required this.bankBalance,
    required this.offerwallBalance,
    required this.adsBalance,
    required this.xp,
    required this.totalClaims,
    required this.faucetClaims,
    required this.lastClaimTime,
  });
}

