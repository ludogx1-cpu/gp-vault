import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/widgets.dart';

class AccountHistoryCard extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final bool isDark;

  const AccountHistoryCard({
    super.key,
    required this.userData,
    required this.isDark,
  });

  @override
  State<AccountHistoryCard> createState() => _AccountHistoryCardState();
}

class _AccountHistoryCardState extends State<AccountHistoryCard> {
  int _historyPage = 0;

  @override
  Widget build(BuildContext context) {
    List<dynamic> history = widget.userData?['reward_history'] ?? [];

    return AnimatedHoverCard(
      backgroundColor: widget.isDark ? Colors.grey.shade900 : Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: Colors.amber,
        width: 0.5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: widget.isDark ? Colors.amber : Colors.black87,
                ),
                const SizedBox(width: 10),
                Text(
                  "Latest Rewards History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    GoRouter.of(context).push('/reward-history');
                  },
                  child: const Text('View Full Audit', style: TextStyle(color: Colors.amber)),
                ),
              ],
            ),
            Divider(
              height: 20,
              color: widget.isDark
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.amber.shade100,
            ),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "No rewards yet. Start earning!",
                    style: TextStyle(
                      color: widget.isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final int itemsPerPage = 10;
                  final int totalPages = (history.length / itemsPerPage).ceil();

                  if (_historyPage >= totalPages) {
                    _historyPage = totalPages - 1;
                    if (_historyPage < 0) _historyPage = 0;
                  }

                  final int startIndex = _historyPage * itemsPerPage;
                  final int endIndex =
                      (startIndex + itemsPerPage > history.length)
                      ? history.length
                      : startIndex + itemsPerPage;
                  final List<dynamic> currentHistory = history.sublist(
                    startIndex,
                    endIndex,
                  );

                  return Column(
                    children: [
                      ...currentHistory.map((item) {
                        final sectorRaw = item['sector']?.toString() ?? 'Unknown';
                        final sector = sectorRaw.replaceAll('\n', ' ');
                        
                        String amountStr = '0.0';
                        final amt = item['amount'];
                        if (amt != null) {
                          final doubleVal = double.tryParse(amt.toString());
                          if (doubleVal != null) {
                            amountStr = doubleVal.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
                          } else {
                            amountStr = amt.toString();
                          }
                        }
                        final ts = item['timestamp'] as int?;
                        String timeStr = 'Unknown Date';
                        if (ts != null) {
                          final date = DateTime.fromMillisecondsSinceEpoch(ts);
                          final ampm = date.hour >= 12 ? 'PM' : 'AM';
                          final hour12 = date.hour % 12 == 0
                              ? 12
                              : date.hour % 12;
                          timeStr =
                              '${date.month}/${date.day}/${date.year} at $hour12:${date.minute.toString().padLeft(2, '0')} $ampm';
                        }

                        IconData icon;
                        if (sector.contains('Faucet')) {
                          icon = Icons.water_drop;
                        } else if (sector.contains('PTC')) {
                          icon = Icons.ads_click;
                        } else if (sector.contains('Pet')) {
                          icon = Icons.pets;
                        } else if (sector.contains('Offer')) {
                          icon = Icons.card_giftcard;
                        } else {
                          icon = Icons.monetization_on;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.amber.withValues(
                                  alpha: 0.2,
                                ),
                                child: Icon(icon, color: Colors.amber, size: 20),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sector,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: widget.isDark ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: widget.isDark ? Colors.white54 : Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+$amountStr DOGE',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
              if ((history.length / 10).ceil() > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _historyPage > 0
                            ? () => setState(() => _historyPage--)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Prev'),
                      ),
                      Text(
                        'Page ${_historyPage + 1} of ${(history.length / 10).ceil()}',
                        style: TextStyle(
                          color: widget.isDark ? Colors.white54 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _historyPage < (history.length / 10).ceil() - 1
                            ? () => setState(() => _historyPage++)
                            : null,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Next'),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
