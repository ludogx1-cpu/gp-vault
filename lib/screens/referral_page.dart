import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../src/referral_service.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final TextEditingController _codeController = TextEditingController();
  Future<Map<String, dynamic>?>? _stats;
  bool _claiming = false;
  String? _claimMessage;
  bool _claimOk = false;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) _stats = ReferralService.stats();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _useCode() async {
    setState(() {
      _claiming = true;
      _claimMessage = null;
    });
    final result = await ReferralService.claim(_codeController.text);
    if (!mounted) return;
    setState(() {
      _claiming = false;
      _claimOk = result.ok;
      _claimMessage = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final refLink = user != null ? ReferralService.inviteLink(user.uid) : null;

    return AppScaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: ListenableBuilder(
          listenable: themeProvider,
          builder: (context, _) {
            final isDark = themeProvider.isDarkMode;
            final titleColor = isDark ? Colors.white : Colors.black87;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Bitcotasks728x90AdWidget(),
                  const SizedBox(height: 20),
                  const Icon(Icons.group_add, size: 80, color: Colors.purple),
                  const SizedBox(height: 20),
                  Text(
                    "Get a 20% Referral Bonus!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Share your link. Every time a friend you invited claims from the faucet, "
                    "Golden Paw adds a bonus worth 20% of their claim to your balance. "
                    "Your friend's own reward isn't reduced.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Bonuses are paid on claims by friends who have verified their email. "
                    "Friends must use your link or code within 7 days of creating their account. "
                    "Inviting yourself or using duplicate accounts isn't allowed and may lead to your account being closed.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Your Unique Link:",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          refLink ?? "Log in to get your referral link!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        if (refLink != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Your code: ${user!.uid.substring(0, 8)}",
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: refLink));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Link copied!")),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18, color: Colors.purple),
                            label: const Text("Copy link", style: TextStyle(color: Colors.purple)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 24),
                    _buildUseCodeBox(titleColor),
                  ],
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Your Referral Network",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (user == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("Log in to see your referral stats!", style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    _buildNetwork(),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    child: const Text(
                      "Back to Faucet",
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUseCodeBox(Color titleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Were you invited by a friend?",
              style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 4),
          const Text(
            "Enter their code within 7 days of creating your account.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  maxLength: 40,
                  style: TextStyle(color: titleColor),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'Friend\'s code',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _claiming ? null : _useCode,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                child: _claiming
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Use code"),
              ),
            ],
          ),
          if (_claimMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _claimMessage!,
              style: TextStyle(color: _claimOk ? Colors.green : Colors.redAccent, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetwork() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _stats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final data = snapshot.data;
        if (data == null) {
          return const Text("Could not load your referral stats. Please try again later.",
              style: TextStyle(color: Colors.grey));
        }
        final referrals = List<Map<String, dynamic>>.from(data['referrals'] as List? ?? []);
        if (referrals.isEmpty) {
          return Card(
            elevation: 0,
            color: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "You haven't referred any users yet. Share your link to start collecting referral bonuses!",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final total = (data['total'] as num? ?? 0).toDouble();
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "${referrals.length} friend${referrals.length == 1 ? '' : 's'} · ${total.toStringAsFixed(6)} DOGE earned",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Friend', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                  DataColumn(label: Text('Earned (20%)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                ],
                rows: referrals.map((r) {
                  final earned = (r['earned'] as num? ?? 0).toDouble();
                  return DataRow(cells: [
                    DataCell(Text("${r['id']}...", style: const TextStyle(color: Colors.black87))),
                    DataCell(Text(
                      "${earned.toStringAsFixed(6)} DOGE",
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    )),
                  ]);
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
