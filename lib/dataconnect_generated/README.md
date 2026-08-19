# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetUserById
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getUserById(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetUserByIdData, GetUserByIdVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getUserById(
  id: id,
);
GetUserByIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getUserById(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetRecentChatMessages
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getRecentChatMessages().execute();
```

#### Optional Arguments
We return a builder for each query. For GetRecentChatMessages, we created `GetRecentChatMessagesBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetRecentChatMessagesVariablesBuilder {
  ...
 
  GetRecentChatMessagesVariablesBuilder limit(int? t) {
   _limit.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.getRecentChatMessages()
.limit(limit)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetRecentChatMessagesData, GetRecentChatMessagesVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getRecentChatMessages();
GetRecentChatMessagesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getRecentChatMessages().ref();
ref.execute();

ref.subscribe(...);
```


### GetAppUpdates
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getAppUpdates().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAppUpdatesData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getAppUpdates();
GetAppUpdatesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getAppUpdates().ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateUser
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.createUser(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateUserData, CreateUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createUser(
  id: id,
);
CreateUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.createUser(
  id: id,
).ref();
ref.execute();
```


### UpdateUserBalances
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.updateUserBalances(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateUserBalances, we created `UpdateUserBalancesBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateUserBalancesVariablesBuilder {
  ...
   UpdateUserBalancesVariablesBuilder dogeBalance(double? t) {
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

  ...
}
ExampleConnector.instance.updateUserBalances(
  id: id,
)
.dogeBalance(dogeBalance)
.stakedBalance(stakedBalance)
.bankBalance(bankBalance)
.xp(xp)
.totalClaims(totalClaims)
.faucetClaims(faucetClaims)
.lastClaimTime(lastClaimTime)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateUserBalancesData, UpdateUserBalancesVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateUserBalances(
  id: id,
);
UpdateUserBalancesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.updateUserBalances(
  id: id,
).ref();
ref.execute();
```


### UpdatePetStats
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.updatePetStats(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdatePetStats, we created `UpdatePetStatsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdatePetStatsVariablesBuilder {
  ...
   UpdatePetStatsVariablesBuilder petHunger(double? t) {
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

  ...
}
ExampleConnector.instance.updatePetStats(
  id: id,
)
.petHunger(petHunger)
.petHappiness(petHappiness)
.petEnergy(petEnergy)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdatePetStatsData, UpdatePetStatsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updatePetStats(
  id: id,
);
UpdatePetStatsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.updatePetStats(
  id: id,
).ref();
ref.execute();
```


### SendChatMessage
#### Required Arguments
```dart
String userId = ...;
String text = ...;
ExampleConnector.instance.sendChatMessage(
  userId: userId,
  text: text,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<SendChatMessageData, SendChatMessageVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.sendChatMessage(
  userId: userId,
  text: text,
);
SendChatMessageData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String userId = ...;
String text = ...;

final ref = ExampleConnector.instance.sendChatMessage(
  userId: userId,
  text: text,
).ref();
ref.execute();
```


### MigrateUser
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.migrateUser(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For MigrateUser, we created `MigrateUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class MigrateUserVariablesBuilder {
  ...
   MigrateUserVariablesBuilder dogeBalance(double? t) {
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

  ...
}
ExampleConnector.instance.migrateUser(
  id: id,
)
.dogeBalance(dogeBalance)
.stakedBalance(stakedBalance)
.bankBalance(bankBalance)
.offerwallBalance(offerwallBalance)
.adsBalance(adsBalance)
.xp(xp)
.role(role)
.totalClaims(totalClaims)
.faucetClaims(faucetClaims)
.lastClaimTime(lastClaimTime)
.stakeTimestamp(stakeTimestamp)
.petBirthDate(petBirthDate)
.petHunger(petHunger)
.petHappiness(petHappiness)
.petEnergy(petEnergy)
.petLastInteraction(petLastInteraction)
.petTotalDistanceWalked(petTotalDistanceWalked)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<MigrateUserData, MigrateUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.migrateUser(
  id: id,
);
MigrateUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.migrateUser(
  id: id,
).ref();
ref.execute();
```

