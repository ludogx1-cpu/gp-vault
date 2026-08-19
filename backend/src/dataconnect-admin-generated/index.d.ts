import { ConnectorConfig, DataConnect, OperationOptions, ExecuteOperationResponse } from 'firebase-admin/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;


export interface AppUpdate_Key {
  id: UUIDString;
  __typename?: 'AppUpdate_Key';
}

export interface ChatMessage_Key {
  id: UUIDString;
  __typename?: 'ChatMessage_Key';
}

export interface CreateUserData {
  user_insert: User_Key;
}

export interface CreateUserVariables {
  id: string;
}

export interface GetAppUpdatesData {
  appUpdates: ({
    id: UUIDString;
    title: string;
    content: string;
    timestamp: TimestampString;
  } & AppUpdate_Key)[];
}

export interface GetRecentChatMessagesData {
  chatMessages: ({
    id: UUIDString;
    text: string;
    timestamp: TimestampString;
    user: {
      id: string;
      role: string;
    } & User_Key;
  } & ChatMessage_Key)[];
}

export interface GetRecentChatMessagesVariables {
  limit?: number | null;
}

export interface GetUserByIdData {
  user?: {
    id: string;
    dogeBalance: number;
    stakedBalance: number;
    bankBalance: number;
    role: string;
    petHunger: number;
    petHappiness: number;
    petEnergy: number;
    petTotalDistanceWalked: number;
    lastClaimTime?: TimestampString | null;
  } & User_Key;
}

export interface GetUserByIdVariables {
  id: string;
}

export interface MigrateUserData {
  user_upsert: User_Key;
}

export interface MigrateUserVariables {
  id: string;
  dogeBalance?: number | null;
  stakedBalance?: number | null;
  bankBalance?: number | null;
  offerwallBalance?: number | null;
  adsBalance?: number | null;
  xp?: number | null;
  role?: string | null;
  totalClaims?: number | null;
  faucetClaims?: number | null;
  lastClaimTime?: TimestampString | null;
  stakeTimestamp?: TimestampString | null;
  petBirthDate?: TimestampString | null;
  petHunger?: number | null;
  petHappiness?: number | null;
  petEnergy?: number | null;
  petLastInteraction?: TimestampString | null;
  petTotalDistanceWalked?: number | null;
}

export interface RewardAudit_Key {
  id: UUIDString;
  __typename?: 'RewardAudit_Key';
}

export interface SendChatMessageData {
  chatMessage_insert: ChatMessage_Key;
}

export interface SendChatMessageVariables {
  userId: string;
  text: string;
}

export interface UpdatePetStatsData {
  user_update?: User_Key | null;
}

export interface UpdatePetStatsVariables {
  id: string;
  petHunger?: number | null;
  petHappiness?: number | null;
  petEnergy?: number | null;
}

export interface UpdateUserBalancesData {
  user_update?: User_Key | null;
}

export interface UpdateUserBalancesVariables {
  id: string;
  dogeBalance?: number | null;
  stakedBalance?: number | null;
  bankBalance?: number | null;
  xp?: number | null;
  totalClaims?: number | null;
  faucetClaims?: number | null;
  lastClaimTime?: TimestampString | null;
}

export interface User_Key {
  id: string;
  __typename?: 'User_Key';
}

/** Generated Node Admin SDK operation action function for the 'CreateUser' Mutation. Allow users to execute without passing in DataConnect. */
export function createUser(dc: DataConnect, vars: CreateUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateUserData>>;
/** Generated Node Admin SDK operation action function for the 'CreateUser' Mutation. Allow users to pass in custom DataConnect instances. */
export function createUser(vars: CreateUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<CreateUserData>>;

/** Generated Node Admin SDK operation action function for the 'UpdateUserBalances' Mutation. Allow users to execute without passing in DataConnect. */
export function updateUserBalances(dc: DataConnect, vars: UpdateUserBalancesVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateUserBalancesData>>;
/** Generated Node Admin SDK operation action function for the 'UpdateUserBalances' Mutation. Allow users to pass in custom DataConnect instances. */
export function updateUserBalances(vars: UpdateUserBalancesVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdateUserBalancesData>>;

/** Generated Node Admin SDK operation action function for the 'UpdatePetStats' Mutation. Allow users to execute without passing in DataConnect. */
export function updatePetStats(dc: DataConnect, vars: UpdatePetStatsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdatePetStatsData>>;
/** Generated Node Admin SDK operation action function for the 'UpdatePetStats' Mutation. Allow users to pass in custom DataConnect instances. */
export function updatePetStats(vars: UpdatePetStatsVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<UpdatePetStatsData>>;

/** Generated Node Admin SDK operation action function for the 'SendChatMessage' Mutation. Allow users to execute without passing in DataConnect. */
export function sendChatMessage(dc: DataConnect, vars: SendChatMessageVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<SendChatMessageData>>;
/** Generated Node Admin SDK operation action function for the 'SendChatMessage' Mutation. Allow users to pass in custom DataConnect instances. */
export function sendChatMessage(vars: SendChatMessageVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<SendChatMessageData>>;

/** Generated Node Admin SDK operation action function for the 'MigrateUser' Mutation. Allow users to execute without passing in DataConnect. */
export function migrateUser(dc: DataConnect, vars: MigrateUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<MigrateUserData>>;
/** Generated Node Admin SDK operation action function for the 'MigrateUser' Mutation. Allow users to pass in custom DataConnect instances. */
export function migrateUser(vars: MigrateUserVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<MigrateUserData>>;

/** Generated Node Admin SDK operation action function for the 'GetUserById' Query. Allow users to execute without passing in DataConnect. */
export function getUserById(dc: DataConnect, vars: GetUserByIdVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetUserByIdData>>;
/** Generated Node Admin SDK operation action function for the 'GetUserById' Query. Allow users to pass in custom DataConnect instances. */
export function getUserById(vars: GetUserByIdVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetUserByIdData>>;

/** Generated Node Admin SDK operation action function for the 'GetRecentChatMessages' Query. Allow users to execute without passing in DataConnect. */
export function getRecentChatMessages(dc: DataConnect, vars?: GetRecentChatMessagesVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetRecentChatMessagesData>>;
/** Generated Node Admin SDK operation action function for the 'GetRecentChatMessages' Query. Allow users to pass in custom DataConnect instances. */
export function getRecentChatMessages(vars?: GetRecentChatMessagesVariables, options?: OperationOptions): Promise<ExecuteOperationResponse<GetRecentChatMessagesData>>;

/** Generated Node Admin SDK operation action function for the 'GetAppUpdates' Query. Allow users to execute without passing in DataConnect. */
export function getAppUpdates(dc: DataConnect, options?: OperationOptions): Promise<ExecuteOperationResponse<GetAppUpdatesData>>;
/** Generated Node Admin SDK operation action function for the 'GetAppUpdates' Query. Allow users to pass in custom DataConnect instances. */
export function getAppUpdates(options?: OperationOptions): Promise<ExecuteOperationResponse<GetAppUpdatesData>>;

