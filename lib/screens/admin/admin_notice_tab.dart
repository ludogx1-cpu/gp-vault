import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNoticeTab extends StatefulWidget {
  const AdminNoticeTab({super.key});

  @override
  State<AdminNoticeTab> createState() => _AdminNoticeTabState();
}

class _AdminNoticeTabState extends State<AdminNoticeTab> {
  final TextEditingController _noticeTitleCtrl = TextEditingController();
  final TextEditingController _noticeMessageCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _injectNotice() async {
    if (_noticeTitleCtrl.text.trim().isEmpty || _noticeMessageCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('updates').add({
        'title': _noticeTitleCtrl.text.trim(),
        'message': _noticeMessageCtrl.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _noticeTitleCtrl.clear();
      _noticeMessageCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notice Posted!"), backgroundColor: Colors.green),
      );
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _noticeTitleCtrl.dispose();
    _noticeMessageCtrl.dispose();
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
                  const Text("Post to Update Board", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  TextField(controller: _noticeTitleCtrl, decoration: const InputDecoration(labelText: "Update Title")),
                  TextField(controller: _noticeMessageCtrl, decoration: const InputDecoration(labelText: "Update Message"), maxLines: 3),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _injectNotice,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("POST UPDATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text("Active Updates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('updates').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.campaign, color: Colors.orange),
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(data['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance.collection('updates').doc(doc.id).delete(),
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
