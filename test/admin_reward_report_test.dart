import 'package:flutter_test/flutter_test.dart';
import 'package:gp_faucet/src/reward_report_export.dart';

void main() {
  group('reward report export', () {
    test('creates CSV rows with header and selected transactions', () {
      final transactions = [
        {
          'type': 'faucet_claim',
          'uid': 'user-1',
          'amount': 0.012,
          'timestamp': DateTime.utc(2026, 8, 17, 9, 30, 0),
        },
        {
          'type': 'withdrawal',
          'uid': 'user-2',
          'amount': -0.004,
          'timestamp': DateTime.utc(2026, 8, 17, 9, 35, 0),
        },
      ];

      final csv = buildRewardReportCsv(transactions, filterLabel: 'faucet_claim');

      expect(csv, contains('filter,type,uid,amount,dogecoin,ts'));
      expect(csv, contains('faucet_claim,faucet_claim,user-1,0.012,0.012000'));
      expect(csv, isNot(contains('withdrawal,withdrawal,user-2,-0.004')));
    });
  });
}
