import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPtcTab extends StatefulWidget {
  const AdminPtcTab({super.key});

  @override
  State<AdminPtcTab> createState() => _AdminPtcTabState();
}

class _AdminPtcTabState extends State<AdminPtcTab> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController(text: "10");
  final TextEditingController _rewardCtrl = TextEditingController(text: "0.0005");
  final TextEditingController _clicksCtrl = TextEditingController(text: "1000");

  bool _isLoading = false;

  Future<void> _injectAd() async {
    if (_titleCtrl.text.trim().isEmpty || _urlCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('ptc_ads').add({
        'title': _titleCtrl.text.trim(),
        'target_url': _urlCtrl.text.trim(),
        'duration': int.tryParse(_durationCtrl.text) ?? 10,
        'reward': double.tryParse(_rewardCtrl.text) ?? 0.001,
        'clicks_remaining': int.tryParse(_clicksCtrl.text) ?? 1000,
        'created_at': FieldValue.serverTimestamp(),
      });
      _titleCtrl.clear();
      _urlCtrl.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PTC Ad Injected!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      // ignore: empty_catches
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _durationCtrl.dispose();
    _rewardCtrl.dispose();
    _clicksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Ad Title",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: "Target URL",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _durationCtrl,
                          decoration: const InputDecoration(
                            labelText: "Timer (Seconds)",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _rewardCtrl,
                          decoration: const InputDecoration(
                            labelText: "DOGE Reward",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _clicksCtrl,
                    decoration: const InputDecoration(
                      labelText: "Total Clicks Available",
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _injectAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        "PUSH AD LIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Live Ad Management",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ptc_ads')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.campaign,
                        color: Colors.orange,
                      ),
                      title: Text(data['title'] ?? 'No Title'),
                      subtitle: Text(
                        "${data['reward']} DOGE | ${data['duration']}s",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('ptc_ads')
                            .doc(doc.id)
                            .delete(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
