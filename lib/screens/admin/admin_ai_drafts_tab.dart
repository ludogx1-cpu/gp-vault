import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAiDraftsTab extends StatefulWidget {
  const AdminAiDraftsTab({super.key});

  @override
  State<AdminAiDraftsTab> createState() => _AdminAiDraftsTabState();
}

class _AdminAiDraftsTabState extends State<AdminAiDraftsTab> {
  final TextEditingController _blogTopicCtrl = TextEditingController();
  final TextEditingController _blogExtUrlCtrl = TextEditingController();
  final TextEditingController _blogContentCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _injectManualBlog() async {
    if (_blogTopicCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('blog_posts').add({
        'topic': _blogTopicCtrl.text.trim(),
        'external_url': _blogExtUrlCtrl.text.trim(),
        'content': _blogContentCtrl.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
      _blogTopicCtrl.clear();
      _blogExtUrlCtrl.clear();
      _blogContentCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Blog Post Published!"), backgroundColor: Colors.green),
      );
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _blogTopicCtrl.dispose();
    _blogExtUrlCtrl.dispose();
    _blogContentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- MANUAL BLOG POST FORM ---
        Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  const Text("Manually Add Blog Post", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  TextField(controller: _blogTopicCtrl, decoration: const InputDecoration(labelText: "Blog Title")),
                  TextField(controller: _blogExtUrlCtrl, decoration: const InputDecoration(labelText: "External URL (Substack/Medium) (Optional)")),
                  TextField(controller: _blogContentCtrl, decoration: const InputDecoration(labelText: "Markdown Content (Optional if URL provided)"), maxLines: 3),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity, height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _injectManualBlog,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("PUBLISH MANUAL POST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
