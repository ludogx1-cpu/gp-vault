import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBonusSponsorsTab extends StatefulWidget {
  const AdminBonusSponsorsTab({super.key});

  @override
  State<AdminBonusSponsorsTab> createState() => _AdminBonusSponsorsTabState();
}

class _AdminBonusSponsorsTabState extends State<AdminBonusSponsorsTab> {
  final TextEditingController _bTitleCtrl = TextEditingController();
  final TextEditingController _bImgCtrl = TextEditingController();
  final TextEditingController _bUrlCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _injectBonusSponsor() async {
    if (_bTitleCtrl.text.trim().isEmpty || _bUrlCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('bonus_sponsors').add({
        'title': _bTitleCtrl.text.trim(),
        'image_url': _bImgCtrl.text.trim(),
        'target_url': _bUrlCtrl.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
      _bTitleCtrl.clear();
      _bImgCtrl.clear();
      _bUrlCtrl.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sponsor Card Added!"),
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
    _bTitleCtrl.dispose();
    _bImgCtrl.dispose();
    _bUrlCtrl.dispose();
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
                  const Text(
                    "Add Visual Sponsor Banner",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  TextField(
                    controller: _bTitleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Sponsor Title",
                    ),
                  ),
                  TextField(
                    controller: _bImgCtrl,
                    decoration: const InputDecoration(
                      labelText: "Banner Image URL",
                    ),
                  ),
                  TextField(
                    controller: _bUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: "Target Affiliate URL",
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _injectBonusSponsor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text(
                        "INJECT SPONSOR CARD",
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
          const SizedBox(height: 25),
          const Text(
            "Active Sponsor Cards",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bonus_sponsors')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
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
                        Icons.card_giftcard,
                        color: Colors.purple,
                      ),
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(
                        data['target_url'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('bonus_sponsors')
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
