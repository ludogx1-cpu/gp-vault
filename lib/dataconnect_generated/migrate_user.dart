part of 'generated.dart';

class MigrateUserVariablesBuilder {
  String id;
  Optional<double> _dogeBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _stakedBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _bankBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _offerwallBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _adsBalance = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _xp = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _role = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _totalClaims = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _faucetClaims = Optional.optional(nativeFromJson, nativeToJson);
  Optional<Timestamp> _lastClaimTime = Optional.optional((json) => json['lastClaimTime'] = Timestamp.fromJson(json['lastClaimTime']), defaultSerializer);
  Optional<Timestamp> _stakeTimestamp = Optional.optional((json) => json['stakeTimestamp'] = Timestamp.fromJson(json['stakeTimestamp']), defaultSerializer);
  Optional<Timestamp> _petBirthDate = Optional.optional((json) => json['petBirthDate'] = Timestamp.fromJson(json['petBirthDate']), defaultSerializer);
  Optional<double> _petHunger = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _petHappiness = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _petEnergy = Optional.optional(nativeFromJson, nativeToJson);
  Optional<Timestamp> _petLastInteraction = Optional.optional((json) => json['petLastInteraction'] = Timestamp.fromJson(json['petLastInteraction']), defaultSerializer);
  Optional<double> _petTotalDistanceWalked = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  MigrateUserVariablesBuilder dogeBalance(double? t) {
   _dogeBalance.value = t;
   return this;
  }
  MigrateUserVariablesBuilder stakedBalance(double? t) {
   _stakedBalance.value = t;
   return this;
  }
  MigrateUserVariablesBuilder bankBalance(double? t) {
   _bankBalance.value = t;
   return this;
  }
  MigrateUserVariablesBuilder offerwallBalance(double? t) {
   _offerwallBalance.value = t;
   return this;
  }
  MigrateUserVariablesBuilder adsBalance(double? t) {
   _adsBalance.value = t;
   return this;
  }
  MigrateUserVariablesBuilder xp(int? t) {
   _xp.value = t;
   return this;
  }
  MigrateUserVariablesBuilder role(String? t) {
   _role.value = t;
   return this;
  }
  MigrateUserVariablesBuilder totalClaims(int? t) {
   _totalClaims.value = t;
   return this;
  }
  MigrateUserVariablesBuilder faucetClaims(int? t) {
   _faucetClaims.value = t;
   return this;
  }
  MigrateUserVariablesBuilder lastClaimTime(Timestamp? t) {
   _lastClaimTime.value = t;
   return this;
  }
  MigrateUserVariablesBuilder stakeTimestamp(Timestamp? t) {
   _stakeTimestamp.value = t;
   return this;
  }
  MigrateUserVariablesBuilder petBirthDate(Timestamp? t) {
   _petBirthDate.value = t;
   return this;
  }
  MigrateUserVariablesBuilder petHunger(double? t) {
   _petHunger.value = t;
   return this;
  }
  MigrateUserVariablesBuilder petHappiness(double? t) {
   _petHappiness.value = t;
   return this;
  }
  MigrateUserVariablesBuilder petEnergy(double? t) {
   _petEnergy.value = t;
   return this;
  }
  MigrateUserVariablesBuilder petLastInteraction(Timestamp? t) {
   _petLastInteraction.value = t;
   return this;
  }
  MigrateUserVariablesBuilder petTotalDistanceWalked(double? t) {
   _petTotalDistanceWalked.value = t;
   return this;
  }

  MigrateUserVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<MigrateUserData> dataDeserializer = (dynamic json)  => MigrateUserData.fromJson(jsonDecode(json));
  Serializer<MigrateUserVariables> varsSerializer = (MigrateUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<MigrateUserData, MigrateUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<MigrateUserData, MigrateUserVariables> ref() {
    MigrateUserVariables vars= MigrateUserVariables(id: id,dogeBalance: _dogeBalance,stakedBalance: _stakedBalance,bankBalance: _bankBalance,offerwallBalance: _offerwallBalance,adsBalance: _adsBalance,xp: _xp,role: _role,totalClaims: _totalClaims,faucetClaims: _faucetClaims,lastClaimTime: _lastClaimTime,stakeTimestamp: _stakeTimestamp,petBirthDate: _petBirthDate,petHunger: _petHunger,petHappiness: _petHappiness,petEnergy: _petEnergy,petLastInteraction: _petLastInteraction,petTotalDistanceWalked: _petTotalDistanceWalked,);
    return _dataConnect.mutation("MigrateUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class MigrateUserUserUpsert {
  final String id;
  MigrateUserUserUpsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MigrateUserUserUpsert otherTyped = other as MigrateUserUserUpsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  MigrateUserUserUpsert({
    required this.id,
  });
}

@immutable
class MigrateUserData {
  final MigrateUserUserUpsert user_upsert;
  MigrateUserData.fromJson(dynamic json):
  
  user_upsert = MigrateUserUserUpsert.fromJson(json['user_upsert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MigrateUserData otherTyped = other as MigrateUserData;
    return user_upsert == otherTyped.user_upsert;
    
  }
  @override
  int get hashCode => user_upsert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_upsert'] = user_upsert.toJson();
    return json;
  }

  MigrateUserData({
    required this.user_upsert,
  });
}

@immutable
class MigrateUserVariables {
  final String id;
  late final Optional<double>dogeBalance;
  late final Optional<double>stakedBalance;
  late final Optional<double>bankBalance;
  late final Optional<double>offerwallBalance;
  late final Optional<double>adsBalance;
  late final Optional<int>xp;
  late final Optional<String>role;
  late final Optional<int>totalClaims;
  late final Optional<int>faucetClaims;
  late final Optional<Timestamp>lastClaimTime;
  late final Optional<Timestamp>stakeTimestamp;
  late final Optional<Timestamp>petBirthDate;
  late final Optional<double>petHunger;
  late final Optional<double>petHappiness;
  late final Optional<double>petEnergy;
  late final Optional<Timestamp>petLastInteraction;
  late final Optional<double>petTotalDistanceWalked;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  MigrateUserVariables.fromJson(Map<String, dynamic> json):
  
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
  
  
    role = Optional.optional(nativeFromJson, nativeToJson);
    role.value = json['role'] == null ? null : nativeFromJson<String>(json['role']);
  
  
    totalClaims = Optional.optional(nativeFromJson, nativeToJson);
    totalClaims.value = json['totalClaims'] == null ? null : nativeFromJson<int>(json['totalClaims']);
  
  
    faucetClaims = Optional.optional(nativeFromJson, nativeToJson);
    faucetClaims.value = json['faucetClaims'] == null ? null : nativeFromJson<int>(json['faucetClaims']);
  
  
    lastClaimTime = Optional.optional((json) => json['lastClaimTime'] = Timestamp.fromJson(json['lastClaimTime']), defaultSerializer);
    lastClaimTime.value = json['lastClaimTime'] == null ? null : Timestamp.fromJson(json['lastClaimTime']);
  
  
    stakeTimestamp = Optional.optional((json) => json['stakeTimestamp'] = Timestamp.fromJson(json['stakeTimestamp']), defaultSerializer);
    stakeTimestamp.value = json['stakeTimestamp'] == null ? null : Timestamp.fromJson(json['stakeTimestamp']);
  
  
    petBirthDate = Optional.optional((json) => json['petBirthDate'] = Timestamp.fromJson(json['petBirthDate']), defaultSerializer);
    petBirthDate.value = json['petBirthDate'] == null ? null : Timestamp.fromJson(json['petBirthDate']);
  
  
    petHunger = Optional.optional(nativeFromJson, nativeToJson);
    petHunger.value = json['petHunger'] == null ? null : nativeFromJson<double>(json['petHunger']);
  
  
    petHappiness = Optional.optional(nativeFromJson, nativeToJson);
    petHappiness.value = json['petHappiness'] == null ? null : nativeFromJson<double>(json['petHappiness']);
  
  
    petEnergy = Optional.optional(nativeFromJson, nativeToJson);
    petEnergy.value = json['petEnergy'] == null ? null : nativeFromJson<double>(json['petEnergy']);
  
  
    petLastInteraction = Optional.optional((json) => json['petLastInteraction'] = Timestamp.fromJson(json['petLastInteraction']), defaultSerializer);
    petLastInteraction.value = json['petLastInteraction'] == null ? null : Timestamp.fromJson(json['petLastInteraction']);
  
  
    petTotalDistanceWalked = Optional.optional(nativeFromJson, nativeToJson);
    petTotalDistanceWalked.value = json['petTotalDistanceWalked'] == null ? null : nativeFromJson<double>(json['petTotalDistanceWalked']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MigrateUserVariables otherTyped = other as MigrateUserVariables;
    return id == otherTyped.id && 
    dogeBalance == otherTyped.dogeBalance && 
    stakedBalance == otherTyped.stakedBalance && 
    bankBalance == otherTyped.bankBalance && 
    offerwallBalance == otherTyped.offerwallBalance && 
    adsBalance == otherTyped.adsBalance && 
    xp == otherTyped.xp && 
    role == otherTyped.role && 
    totalClaims == otherTyped.totalClaims && 
    faucetClaims == otherTyped.faucetClaims && 
    lastClaimTime == otherTyped.lastClaimTime && 
    stakeTimestamp == otherTyped.stakeTimestamp && 
    petBirthDate == otherTyped.petBirthDate && 
    petHunger == otherTyped.petHunger && 
    petHappiness == otherTyped.petHappiness && 
    petEnergy == otherTyped.petEnergy && 
    petLastInteraction == otherTyped.petLastInteraction && 
    petTotalDistanceWalked == otherTyped.petTotalDistanceWalked;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, dogeBalance.hashCode, stakedBalance.hashCode, bankBalance.hashCode, offerwallBalance.hashCode, adsBalance.hashCode, xp.hashCode, role.hashCode, totalClaims.hashCode, faucetClaims.hashCode, lastClaimTime.hashCode, stakeTimestamp.hashCode, petBirthDate.hashCode, petHunger.hashCode, petHappiness.hashCode, petEnergy.hashCode, petLastInteraction.hashCode, petTotalDistanceWalked.hashCode]);
  

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
    if(role.state == OptionalState.set) {
      json['role'] = role.toJson();
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
    if(stakeTimestamp.state == OptionalState.set) {
      json['stakeTimestamp'] = stakeTimestamp.toJson();
    }
    if(petBirthDate.state == OptionalState.set) {
      json['petBirthDate'] = petBirthDate.toJson();
    }
    if(petHunger.state == OptionalState.set) {
      json['petHunger'] = petHunger.toJson();
    }
    if(petHappiness.state == OptionalState.set) {
      json['petHappiness'] = petHappiness.toJson();
    }
    if(petEnergy.state == OptionalState.set) {
      json['petEnergy'] = petEnergy.toJson();
    }
    if(petLastInteraction.state == OptionalState.set) {
      json['petLastInteraction'] = petLastInteraction.toJson();
    }
    if(petTotalDistanceWalked.state == OptionalState.set) {
      json['petTotalDistanceWalked'] = petTotalDistanceWalked.toJson();
    }
    return json;
  }

  MigrateUserVariables({
    required this.id,
    required this.dogeBalance,
    required this.stakedBalance,
    required this.bankBalance,
    required this.offerwallBalance,
    required this.adsBalance,
    required this.xp,
    required this.role,
    required this.totalClaims,
    required this.faucetClaims,
    required this.lastClaimTime,
    required this.stakeTimestamp,
    required this.petBirthDate,
    required this.petHunger,
    required this.petHappiness,
    required this.petEnergy,
    required this.petLastInteraction,
    required this.petTotalDistanceWalked,
  });
}

