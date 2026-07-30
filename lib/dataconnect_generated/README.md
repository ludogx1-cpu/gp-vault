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

### GetMyUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getMyUser().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyUserData, void>`
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

final result = await ExampleConnector.instance.getMyUser();
GetMyUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getMyUser().ref();
ref.execute();

ref.subscribe(...);
```


### ListAllUsers
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listAllUsers().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListAllUsersData, void>`
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

final result = await ExampleConnector.instance.listAllUsers();
ListAllUsersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listAllUsers().ref();
ref.execute();

ref.subscribe(...);
```


### GetSkill
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getSkill(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSkillData, GetSkillVariables>`
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

final result = await ExampleConnector.instance.getSkill(
  id: id,
);
GetSkillData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getSkill(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListSkills
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listSkills().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListSkillsData, void>`
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

final result = await ExampleConnector.instance.listSkills();
ListSkillsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listSkills().ref();
ref.execute();

ref.subscribe(...);
```


### GetUserSkill
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getUserSkill(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetUserSkillData, GetUserSkillVariables>`
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

final result = await ExampleConnector.instance.getUserSkill(
  id: id,
);
GetUserSkillData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getUserSkill(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMySkills
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listMySkills().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMySkillsData, void>`
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

final result = await ExampleConnector.instance.listMySkills();
ListMySkillsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listMySkills().ref();
ref.execute();

ref.subscribe(...);
```


### GetSession
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getSession(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSessionData, GetSessionVariables>`
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

final result = await ExampleConnector.instance.getSession(
  id: id,
);
GetSessionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getSession(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMySessions
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listMySessions().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMySessionsData, void>`
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

final result = await ExampleConnector.instance.listMySessions();
ListMySessionsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listMySessions().ref();
ref.execute();

ref.subscribe(...);
```


### GetReview
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getReview(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetReviewData, GetReviewVariables>`
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

final result = await ExampleConnector.instance.getReview(
  id: id,
);
GetReviewData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getReview(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListReviewsForSession
#### Required Arguments
```dart
String sessionId = ...;
ExampleConnector.instance.listReviewsForSession(
  sessionId: sessionId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListReviewsForSessionData, ListReviewsForSessionVariables>`
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

final result = await ExampleConnector.instance.listReviewsForSession(
  sessionId: sessionId,
);
ListReviewsForSessionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String sessionId = ...;

final ref = ExampleConnector.instance.listReviewsForSession(
  sessionId: sessionId,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateUserAccount
#### Required Arguments
```dart
String displayName = ...;
String email = ...;
String bio = ...;
ExampleConnector.instance.createUserAccount(
  displayName: displayName,
  email: email,
  bio: bio,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateUserAccountData, CreateUserAccountVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createUserAccount(
  displayName: displayName,
  email: email,
  bio: bio,
);
CreateUserAccountData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String displayName = ...;
String email = ...;
String bio = ...;

final ref = ExampleConnector.instance.createUserAccount(
  displayName: displayName,
  email: email,
  bio: bio,
).ref();
ref.execute();
```


### UpdateMyUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.updateMyUser().execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateMyUser, we created `UpdateMyUserBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateMyUserVariablesBuilder {
  ...
 
  UpdateMyUserVariablesBuilder displayName(String? t) {
   _displayName.value = t;
   return this;
  }
  UpdateMyUserVariablesBuilder bio(String? t) {
   _bio.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.updateMyUser()
.displayName(displayName)
.bio(bio)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateMyUserData, UpdateMyUserVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateMyUser();
UpdateMyUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.updateMyUser().ref();
ref.execute();
```


### DeleteMyUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.deleteMyUser().execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteMyUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteMyUser();
DeleteMyUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.deleteMyUser().ref();
ref.execute();
```


### CreateSkill
#### Required Arguments
```dart
String name = ...;
String category = ...;
ExampleConnector.instance.createSkill(
  name: name,
  category: category,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateSkillData, CreateSkillVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createSkill(
  name: name,
  category: category,
);
CreateSkillData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String name = ...;
String category = ...;

final ref = ExampleConnector.instance.createSkill(
  name: name,
  category: category,
).ref();
ref.execute();
```


### UpdateSkill
#### Required Arguments
```dart
String id = ...;
String category = ...;
ExampleConnector.instance.updateSkill(
  id: id,
  category: category,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateSkillData, UpdateSkillVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateSkill(
  id: id,
  category: category,
);
UpdateSkillData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String category = ...;

final ref = ExampleConnector.instance.updateSkill(
  id: id,
  category: category,
).ref();
ref.execute();
```


### DeleteSkill
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteSkill(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteSkillData, DeleteSkillVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteSkill(
  id: id,
);
DeleteSkillData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteSkill(
  id: id,
).ref();
ref.execute();
```


### AddUserSkill
#### Required Arguments
```dart
String skillId = ...;
String level = ...;
ExampleConnector.instance.addUserSkill(
  skillId: skillId,
  level: level,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<AddUserSkillData, AddUserSkillVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.addUserSkill(
  skillId: skillId,
  level: level,
);
AddUserSkillData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String skillId = ...;
String level = ...;

final ref = ExampleConnector.instance.addUserSkill(
  skillId: skillId,
  level: level,
).ref();
ref.execute();
```


### UpdateUserSkill
#### Required Arguments
```dart
String id = ...;
String level = ...;
ExampleConnector.instance.updateUserSkill(
  id: id,
  level: level,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateUserSkillData, UpdateUserSkillVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateUserSkill(
  id: id,
  level: level,
);
UpdateUserSkillData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String level = ...;

final ref = ExampleConnector.instance.updateUserSkill(
  id: id,
  level: level,
).ref();
ref.execute();
```


### RemoveUserSkill
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.removeUserSkill(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<RemoveUserSkillData, RemoveUserSkillVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.removeUserSkill(
  id: id,
);
RemoveUserSkillData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.removeUserSkill(
  id: id,
).ref();
ref.execute();
```


### ProposeSession
#### Required Arguments
```dart
String recipientId = ...;
Timestamp scheduledDate = ...;
ExampleConnector.instance.proposeSession(
  recipientId: recipientId,
  scheduledDate: scheduledDate,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ProposeSessionData, ProposeSessionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.proposeSession(
  recipientId: recipientId,
  scheduledDate: scheduledDate,
);
ProposeSessionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String recipientId = ...;
Timestamp scheduledDate = ...;

final ref = ExampleConnector.instance.proposeSession(
  recipientId: recipientId,
  scheduledDate: scheduledDate,
).ref();
ref.execute();
```


### UpdateSessionStatus
#### Required Arguments
```dart
String id = ...;
String status = ...;
ExampleConnector.instance.updateSessionStatus(
  id: id,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateSessionStatusData, UpdateSessionStatusVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateSessionStatus(
  id: id,
  status: status,
);
UpdateSessionStatusData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String status = ...;

final ref = ExampleConnector.instance.updateSessionStatus(
  id: id,
  status: status,
).ref();
ref.execute();
```


### DeleteSession
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteSession(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteSessionData, DeleteSessionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteSession(
  id: id,
);
DeleteSessionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteSession(
  id: id,
).ref();
ref.execute();
```


### SubmitReview
#### Required Arguments
```dart
String sessionId = ...;
int rating = ...;
String comment = ...;
ExampleConnector.instance.submitReview(
  sessionId: sessionId,
  rating: rating,
  comment: comment,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<SubmitReviewData, SubmitReviewVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.submitReview(
  sessionId: sessionId,
  rating: rating,
  comment: comment,
);
SubmitReviewData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String sessionId = ...;
int rating = ...;
String comment = ...;

final ref = ExampleConnector.instance.submitReview(
  sessionId: sessionId,
  rating: rating,
  comment: comment,
).ref();
ref.execute();
```


### UpdateReview
#### Required Arguments
```dart
String id = ...;
int rating = ...;
String comment = ...;
ExampleConnector.instance.updateReview(
  id: id,
  rating: rating,
  comment: comment,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateReviewData, UpdateReviewVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateReview(
  id: id,
  rating: rating,
  comment: comment,
);
UpdateReviewData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
int rating = ...;
String comment = ...;

final ref = ExampleConnector.instance.updateReview(
  id: id,
  rating: rating,
  comment: comment,
).ref();
ref.execute();
```


### DeleteReview
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteReview(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteReviewData, DeleteReviewVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteReview(
  id: id,
);
DeleteReviewData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteReview(
  id: id,
).ref();
ref.execute();
```

