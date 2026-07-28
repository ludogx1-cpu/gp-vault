import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHtmlSnippetsTab extends StatefulWidget {
  const AdminHtmlSnippetsTab({super.key});

  @override
  State<AdminHtmlSnippetsTab> createState() => _AdminHtmlSnippetsTabState();
}

class _AdminHtmlSnippetsTabState extends State<AdminHtmlSnippetsTab> {
  final TextEditingController _phTitleCtrl = TextEditingController();
  final TextEditingController _phCodeCtrl = TextEditingController();
  String _phPosition = 'Top';

  bool _isLoading = false;

  Future<void> _injectPlaceholder() async {
    if (_phCodeCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('sponsor_placeholders').add({
        'title': _phTitleCtrl.text.trim(),
        'iframe_code': _phCodeCtrl.text.trim(),
        'position': _phPosition,
        'created_at': FieldValue.serverTimestamp(),
      });
      _phTitleCtrl.clear();
      _phCodeCtrl.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("HTML Placeholder Injected!"),
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
    _phTitleCtrl.dispose();
    _phCodeCtrl.dispose();
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
                    "Inject Raw HTML (iFrames)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  TextField(
                    controller: _phTitleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Reference Title (e.g., Top Banner)",
                    ),
                  ),
                  TextField(
                    controller: _phCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Raw iframe Code",
                    ),
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _phPosition,
                    decoration: const InputDecoration(
                      labelText: "Page Position",
                    ),
                    items: ['Top', 'Middle', 'Bottom']
                        .map(
                          (p) => DropdownMenuItem(value: p, child: Text(p)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _phPosition = val!),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _injectPlaceholder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text(
                        "INJECT HTML PLACEHOLDER",
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
            "Active HTML Placeholders",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sponsor_placeholders')
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
                        Icons.code,
                        color: Colors.indigo,
                      ),
                      title: Text(data['title'] ?? 'Unnamed Snippet'),
                      subtitle: Text(
                        "Position: ${data['position'] ?? 'Top'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('sponsor_placeholders')
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
