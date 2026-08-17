String buildRewardReportCsv(
  List<Map<String, dynamic>> transactions, {
    String filterLabel = 'all',
  }) {
  final rows = <String>[
    'filter,type,uid,amount,dogecoin,ts',
  ];

  for (final item in transactions) {
    final type = (item['type'] as String?) ?? 'unknown';
    final uid = (item['uid'] as String?) ?? 'unknown';
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final ts = item['timestamp'];
    final dateText = ts is DateTime
        ? ts.toUtc().toIso8601String()
        : ts?.toString() ?? '';

    if (filterLabel != 'all' && type != filterLabel) {
      continue;
    }

    rows.add('$filterLabel,$type,$uid,$amount,${amount.toStringAsFixed(6)},$dateText');
  }

  return rows.join('\n');
}
