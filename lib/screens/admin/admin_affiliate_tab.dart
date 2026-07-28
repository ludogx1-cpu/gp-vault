import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAffiliateTab extends StatefulWidget {
  const AdminAffiliateTab({super.key});

  @override
  State<AdminAffiliateTab> createState() => _AdminAffiliateTabState();
}

class _AdminAffiliateTabState extends State<AdminAffiliateTab> {
  final TextEditingController _pTitleCtrl = TextEditingController();
  final TextEditingController _pSubCtrl = TextEditingController();
  final TextEditingController _pRewardCtrl = TextEditingController();
  final TextEditingController _pUrlCtrl = TextEditingController();
  String _selectedCategory = 'Wallets';
  String _selectedIcon = 'wallet';
  String _selectedColorHex = '0xFF2196F3';

  bool _isLoading = false;

  Future<void> _injectPartner() async {
    if (_pTitleCtrl.text.trim().isEmpty || _pUrlCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('partners').add({
        'title': _pTitleCtrl.text.trim(),
        'sub': _pSubCtrl.text.trim(),
        'reward': _pRewardCtrl.text.trim(),
        'url': _pUrlCtrl.text.trim(),
        'category': _selectedCategory,
        'iconName': _selectedIcon,
        'colorHex': _selectedColorHex,
      });
      _pTitleCtrl.clear();
      _pSubCtrl.clear();
      _pRewardCtrl.clear();
      _pUrlCtrl.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Partner Link Saved!"),
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
    _pTitleCtrl.dispose();
    _pSubCtrl.dispose();
    _pRewardCtrl.dispose();
    _pUrlCtrl.dispose();
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
                    controller: _pTitleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Platform Title",
                    ),
                  ),
                  TextField(
                    controller: _pSubCtrl,
                    decoration: const InputDecoration(
                      labelText: "Description Subtitle",
                    ),
                  ),
                  TextField(
                    controller: _pRewardCtrl,
                    decoration: const InputDecoration(
                      labelText: "Marketing / Reward Text",
                    ),
                  ),
                  TextField(
                    controller: _pUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: "Affiliate Tracking Link",
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Category",
                    ),
                    items: ['Wallets', 'PTC', 'Faucets', 'Mining', 'Other']
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedIcon,
                    decoration: const InputDecoration(
                      labelText: "Icon Setup",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'wallet',
                        child: Text("Wallet Icon"),
                      ),
                      DropdownMenuItem(
                        value: 'ptc',
                        child: Text("PTC Cursor"),
                      ),
                      DropdownMenuItem(
                        value: 'faucet',
                        child: Text("Water Faucet"),
                      ),
                      DropdownMenuItem(
                        value: 'mining',
                        child: Text("Cloud Sync Engine"),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedIcon = val!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedColorHex,
                    decoration: const InputDecoration(
                      labelText: "Color Tint",
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '0xFF2196F3',
                        child: Text("Blue"),
                      ),
                      DropdownMenuItem(
                        value: '0xFFFF9800',
                        child: Text("Orange"),
                      ),
                      DropdownMenuItem(
                        value: '0xFFE91E63',
                        child: Text("Pink"),
                      ),
                      DropdownMenuItem(
                        value: '0xFF009688',
                        child: Text("Teal"),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedColorHex = val!),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _injectPartner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        "INJECT PARTNER LINK",
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
            "Active Partner Links",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('partners')
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
                      title: Text(data['title'] ?? ''),
                      subtitle: Text("Category: ${data['category']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseFirestore.instance
                            .collection('partners')
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
