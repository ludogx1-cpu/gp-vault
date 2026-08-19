part of 'generated.dart';

class UpdatePetStatsVariablesBuilder {
  String id;
  Optional<double> _petHunger = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _petHappiness = Optional.optional(nativeFromJson, nativeToJson);
  Optional<double> _petEnergy = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdatePetStatsVariablesBuilder petHunger(double? t) {
   _petHunger.value = t;
   return this;
  }
  UpdatePetStatsVariablesBuilder petHappiness(double? t) {
   _petHappiness.value = t;
   return this;
  }
  UpdatePetStatsVariablesBuilder petEnergy(double? t) {
   _petEnergy.value = t;
   return this;
  }

  UpdatePetStatsVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UpdatePetStatsData> dataDeserializer = (dynamic json)  => UpdatePetStatsData.fromJson(jsonDecode(json));
  Serializer<UpdatePetStatsVariables> varsSerializer = (UpdatePetStatsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdatePetStatsData, UpdatePetStatsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdatePetStatsData, UpdatePetStatsVariables> ref() {
    UpdatePetStatsVariables vars= UpdatePetStatsVariables(id: id,petHunger: _petHunger,petHappiness: _petHappiness,petEnergy: _petEnergy,);
    return _dataConnect.mutation("UpdatePetStats", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdatePetStatsUserUpdate {
  final String id;
  UpdatePetStatsUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePetStatsUserUpdate otherTyped = other as UpdatePetStatsUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdatePetStatsUserUpdate({
    required this.id,
  });
}

@immutable
class UpdatePetStatsData {
  final UpdatePetStatsUserUpdate? user_update;
  UpdatePetStatsData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdatePetStatsUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePetStatsData otherTyped = other as UpdatePetStatsData;
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

  UpdatePetStatsData({
    this.user_update,
  });
}

@immutable
class UpdatePetStatsVariables {
  final String id;
  late final Optional<double>petHunger;
  late final Optional<double>petHappiness;
  late final Optional<double>petEnergy;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdatePetStatsVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    petHunger = Optional.optional(nativeFromJson, nativeToJson);
    petHunger.value = json['petHunger'] == null ? null : nativeFromJson<double>(json['petHunger']);
  
  
    petHappiness = Optional.optional(nativeFromJson, nativeToJson);
    petHappiness.value = json['petHappiness'] == null ? null : nativeFromJson<double>(json['petHappiness']);
  
  
    petEnergy = Optional.optional(nativeFromJson, nativeToJson);
    petEnergy.value = json['petEnergy'] == null ? null : nativeFromJson<double>(json['petEnergy']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePetStatsVariables otherTyped = other as UpdatePetStatsVariables;
    return id == otherTyped.id && 
    petHunger == otherTyped.petHunger && 
    petHappiness == otherTyped.petHappiness && 
    petEnergy == otherTyped.petEnergy;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, petHunger.hashCode, petHappiness.hashCode, petEnergy.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(petHunger.state == OptionalState.set) {
      json['petHunger'] = petHunger.toJson();
    }
    if(petHappiness.state == OptionalState.set) {
      json['petHappiness'] = petHappiness.toJson();
    }
    if(petEnergy.state == OptionalState.set) {
      json['petEnergy'] = petEnergy.toJson();
    }
    return json;
  }

  UpdatePetStatsVariables({
    required this.id,
    required this.petHunger,
    required this.petHappiness,
    required this.petEnergy,
  });
}

