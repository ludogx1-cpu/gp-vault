# Basic Usage

```dart
ExampleConnector.instance.CreateUserAccount(createUserAccountVariables).execute();
ExampleConnector.instance.UpdateMyUser(updateMyUserVariables).execute();
ExampleConnector.instance.DeleteMyUser().execute();
ExampleConnector.instance.GetMyUser().execute();
ExampleConnector.instance.ListAllUsers().execute();
ExampleConnector.instance.CreateSkill(createSkillVariables).execute();
ExampleConnector.instance.UpdateSkill(updateSkillVariables).execute();
ExampleConnector.instance.DeleteSkill(deleteSkillVariables).execute();
ExampleConnector.instance.GetSkill(getSkillVariables).execute();
ExampleConnector.instance.ListSkills().execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await ExampleConnector.instance.UpdateMyUser({ ... })
.displayName(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

