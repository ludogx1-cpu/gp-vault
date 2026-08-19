library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_user.dart';

part 'update_user_balances.dart';

part 'update_pet_stats.dart';

part 'send_chat_message.dart';

part 'migrate_user.dart';

part 'get_user_by_id.dart';

part 'get_recent_chat_messages.dart';

part 'get_app_updates.dart';







class ExampleConnector {
  
  
  CreateUserVariablesBuilder createUser ({required String id, }) {
    return CreateUserVariablesBuilder(dataConnect, id: id,);
  }
  
  
  UpdateUserBalancesVariablesBuilder updateUserBalances ({required String id, }) {
    return UpdateUserBalancesVariablesBuilder(dataConnect, id: id,);
  }
  
  
  UpdatePetStatsVariablesBuilder updatePetStats ({required String id, }) {
    return UpdatePetStatsVariablesBuilder(dataConnect, id: id,);
  }
  
  
  SendChatMessageVariablesBuilder sendChatMessage ({required String userId, required String text, }) {
    return SendChatMessageVariablesBuilder(dataConnect, userId: userId,text: text,);
  }
  
  
  MigrateUserVariablesBuilder migrateUser ({required String id, }) {
    return MigrateUserVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetUserByIdVariablesBuilder getUserById ({required String id, }) {
    return GetUserByIdVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetRecentChatMessagesVariablesBuilder getRecentChatMessages () {
    return GetRecentChatMessagesVariablesBuilder(dataConnect, );
  }
  
  
  GetAppUpdatesVariablesBuilder getAppUpdates () {
    return GetAppUpdatesVariablesBuilder(dataConnect, );
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
