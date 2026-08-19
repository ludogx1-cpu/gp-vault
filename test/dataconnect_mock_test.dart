import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:provider/provider.dart';

import 'package:gp_faucet/dataconnect_generated/generated.dart';
import 'package:gp_faucet/screens/faucet/faucet_claim_card.dart';
import 'package:gp_faucet/src/theme_provider.dart';

class MockExampleConnector extends Mock implements ExampleConnector {}
class MockGetUserByIdVariablesBuilder extends Mock implements GetUserByIdVariablesBuilder {}
class MockUser extends Mock implements User {}

class MockQueryResult extends Mock implements QueryResult<GetUserByIdData, GetUserByIdVariables> {}

void main() {
  setUpAll(() {
    registerFallbackValue(QueryFetchPolicy.preferCache);
  });

  testWidgets('FaucetClaimCard respects cooldown from Data Connect', (WidgetTester tester) async {
    final mockConnector = MockExampleConnector();
    final mockUser = MockUser();
    when(() => mockUser.uid).thenReturn('test-user-123');

    // Create a mock timestamp for 2 minutes ago (so we are on cooldown)
    final claimTime = DateTime.now().subtract(const Duration(minutes: 2));
    final mockTimestamp = Timestamp(0, claimTime.millisecondsSinceEpoch ~/ 1000);

    final mockUserData = GetUserByIdData(
      user: GetUserByIdUser(
        id: 'test-user-123',
        dogeBalance: 0,
        stakedBalance: 0,
        bankBalance: 0,
        role: 'user',
        petHunger: 100,
        petHappiness: 100,
        petEnergy: 100,
        petTotalDistanceWalked: 0,
        lastClaimTime: mockTimestamp,
      ),
    );

    final mockBuilder = MockGetUserByIdVariablesBuilder();
    final mockQueryResult = MockQueryResult();
    
    when(() => mockQueryResult.data).thenReturn(mockUserData);
    
    // We must mock the ref() and execute()
    when(() => mockBuilder.execute(fetchPolicy: any(named: 'fetchPolicy')))
        .thenAnswer((_) async => mockQueryResult);

    when(() => mockConnector.getUserById(id: 'test-user-123')).thenReturn(mockBuilder);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
          child: SingleChildScrollView(
            child: FaucetClaimCard(
              connector: mockConnector,
              mockUser: mockUser,
            ),
          ),
        ),
      ),
    ));

    // The widget calls _syncCheckLock in initState, which is async.
    // We need to pump until the Future completes.
    await tester.pumpAndSettle();

    // Since the last claim was 2 minutes ago, the cooldown is 5 minutes (300 seconds).
    // The widget should be in cooldown state, so the text should show remaining time.
    expect(find.textContaining('Wait'), findsOneWidget);
    
    // Verify that the connector was called
    verify(() => mockConnector.getUserById(id: 'test-user-123')).called(1);
    verify(() => mockBuilder.execute(fetchPolicy: any(named: 'fetchPolicy'))).called(1);
  });
}
