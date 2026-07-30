library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_user_account.dart';

part 'update_my_user.dart';

part 'delete_my_user.dart';

part 'get_my_user.dart';

part 'list_all_users.dart';

part 'create_skill.dart';

part 'update_skill.dart';

part 'delete_skill.dart';

part 'get_skill.dart';

part 'list_skills.dart';

part 'add_user_skill.dart';

part 'update_user_skill.dart';

part 'remove_user_skill.dart';

part 'get_user_skill.dart';

part 'list_my_skills.dart';

part 'propose_session.dart';

part 'update_session_status.dart';

part 'delete_session.dart';

part 'get_session.dart';

part 'list_my_sessions.dart';

part 'submit_review.dart';

part 'update_review.dart';

part 'delete_review.dart';

part 'get_review.dart';

part 'list_reviews_for_session.dart';







class ExampleConnector {
  
  
  CreateUserAccountVariablesBuilder createUserAccount ({required String displayName, required String email, required String bio, }) {
    return CreateUserAccountVariablesBuilder(dataConnect, displayName: displayName,email: email,bio: bio,);
  }
  
  
  UpdateMyUserVariablesBuilder updateMyUser () {
    return UpdateMyUserVariablesBuilder(dataConnect, );
  }
  
  
  DeleteMyUserVariablesBuilder deleteMyUser () {
    return DeleteMyUserVariablesBuilder(dataConnect, );
  }
  
  
  GetMyUserVariablesBuilder getMyUser () {
    return GetMyUserVariablesBuilder(dataConnect, );
  }
  
  
  ListAllUsersVariablesBuilder listAllUsers () {
    return ListAllUsersVariablesBuilder(dataConnect, );
  }
  
  
  CreateSkillVariablesBuilder createSkill ({required String name, required String category, }) {
    return CreateSkillVariablesBuilder(dataConnect, name: name,category: category,);
  }
  
  
  UpdateSkillVariablesBuilder updateSkill ({required String id, required String category, }) {
    return UpdateSkillVariablesBuilder(dataConnect, id: id,category: category,);
  }
  
  
  DeleteSkillVariablesBuilder deleteSkill ({required String id, }) {
    return DeleteSkillVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetSkillVariablesBuilder getSkill ({required String id, }) {
    return GetSkillVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListSkillsVariablesBuilder listSkills () {
    return ListSkillsVariablesBuilder(dataConnect, );
  }
  
  
  AddUserSkillVariablesBuilder addUserSkill ({required String skillId, required String level, }) {
    return AddUserSkillVariablesBuilder(dataConnect, skillId: skillId,level: level,);
  }
  
  
  UpdateUserSkillVariablesBuilder updateUserSkill ({required String id, required String level, }) {
    return UpdateUserSkillVariablesBuilder(dataConnect, id: id,level: level,);
  }
  
  
  RemoveUserSkillVariablesBuilder removeUserSkill ({required String id, }) {
    return RemoveUserSkillVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetUserSkillVariablesBuilder getUserSkill ({required String id, }) {
    return GetUserSkillVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListMySkillsVariablesBuilder listMySkills () {
    return ListMySkillsVariablesBuilder(dataConnect, );
  }
  
  
  ProposeSessionVariablesBuilder proposeSession ({required String recipientId, required Timestamp scheduledDate, }) {
    return ProposeSessionVariablesBuilder(dataConnect, recipientId: recipientId,scheduledDate: scheduledDate,);
  }
  
  
  UpdateSessionStatusVariablesBuilder updateSessionStatus ({required String id, required String status, }) {
    return UpdateSessionStatusVariablesBuilder(dataConnect, id: id,status: status,);
  }
  
  
  DeleteSessionVariablesBuilder deleteSession ({required String id, }) {
    return DeleteSessionVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetSessionVariablesBuilder getSession ({required String id, }) {
    return GetSessionVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListMySessionsVariablesBuilder listMySessions () {
    return ListMySessionsVariablesBuilder(dataConnect, );
  }
  
  
  SubmitReviewVariablesBuilder submitReview ({required String sessionId, required int rating, required String comment, }) {
    return SubmitReviewVariablesBuilder(dataConnect, sessionId: sessionId,rating: rating,comment: comment,);
  }
  
  
  UpdateReviewVariablesBuilder updateReview ({required String id, required int rating, required String comment, }) {
    return UpdateReviewVariablesBuilder(dataConnect, id: id,rating: rating,comment: comment,);
  }
  
  
  DeleteReviewVariablesBuilder deleteReview ({required String id, }) {
    return DeleteReviewVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetReviewVariablesBuilder getReview ({required String id, }) {
    return GetReviewVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListReviewsForSessionVariablesBuilder listReviewsForSession ({required String sessionId, }) {
    return ListReviewsForSessionVariablesBuilder(dataConnect, sessionId: sessionId,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'europe-west2',
    'example',
    'gp-vault-main',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
