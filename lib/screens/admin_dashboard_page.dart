import 'package:flutter/material.dart';
import 'dart:async';
import 'package:web/web.dart' as web;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';


// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _adminTabController;

  // Tab 1: PTC fields
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController(text: "10");
  final TextEditingController _rewardCtrl = TextEditingController(
    text: "0.0005",
  );
  final TextEditingController _clicksCtrl = TextEditingController(text: "1000");

  // Tab 2: Partner Links fields
  final TextEditingController _pTitleCtrl = TextEditingController();
  final TextEditingController _pSubCtrl = TextEditingController();
  final TextEditingController _pRewardCtrl = TextEditingController();
  final TextEditingController _pUrlCtrl = TextEditingController();
  String _selectedCategory = 'Wallets';
  String _selectedIcon = 'wallet';
  String _selectedColorHex = '0xFF2196F3';

  // Tab 3: Bonus Sponsor fields
  final TextEditingController _bTitleCtrl = TextEditingController();
  final TextEditingController _bImgCtrl = TextEditingController();
  final TextEditingController _bUrlCtrl = TextEditingController();

  // Tab 4: Raw HTML Placeholder fields
  final TextEditingController _phTitleCtrl = TextEditingController();
  final TextEditingController _phCodeCtrl = TextEditingController();
  String _phPosition = 'Top'; // Ys? NEW: Lets you choose where the ad goes!

  // Tab 5: Notices fields
  final TextEditingController _noticeTitleCtrl = TextEditingController();
  final TextEditingController _noticeMessageCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _adminTabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _adminTabController.dispose();
    super.dispose();
  }

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

  Future<void> _injectPlaceholder() async {
    if (_phCodeCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('sponsor_placeholders').add({
        'title': _phTitleCtrl.text.trim(),
        'iframe_code': _phCodeCtrl.text.trim(),
        'position': _phPosition, // 🚀 SAVES THE POSITION
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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email != 'ludogx1@gmail.com') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BOSS DASHBOARD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 🚀 INSTANT PREVIEW BUTTON (Bypasses 3 hour lock)
          TextButton.icon(
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text(
              "Preview Sponsors",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => web.window.open('/sponsors.html', '_blank'),
          ),
        ],
        bottom: TabBar(
          controller: _adminTabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.ads_click), text: "Manage PTC Ads"),
            Tab(icon: Icon(Icons.handshake), text: "Affiliate Links"),
            Tab(icon: Icon(Icons.card_giftcard), text: "Bonus Sponsors"),
            Tab(icon: Icon(Icons.code), text: "HTML Snippets"),
            Tab(icon: Icon(Icons.campaign), text: "Update Board"),
            Tab(icon: Icon(Icons.psychology), text: "AI Drafts"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _adminTabController,
        children: [
          // --- TAB 1: PTC CONTROLS ---
          SingleChildScrollView(
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
          ),

          // --- TAB 2: PARTNER LINKS ---
          SingleChildScrollView(
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
                          items:
                              ['Wallets', 'PTC', 'Faucets', 'Mining', 'Other']
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val!),
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
                          onChanged: (val) =>
                              setState(() => _selectedIcon = val!),
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
                          onChanged: (val) =>
                              setState(() => _selectedColorHex = val!),
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
          ),

          // --- TAB 3: BONUS SPONSORS (CARDS) ---
          SingleChildScrollView(
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
          ),

          // --- TAB 4: AD PLACEHOLDERS (RAW HTML) ---
          SingleChildScrollView(
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

                        // 🚀 NEW DROPDOWN: Choose Top, Middle, or Bottom
                        DropdownButtonFormField<String>(
                          initialValue: _phPosition,
                          decoration: const InputDecoration(
                            labelText: "Page Position",
                          ),
                          items: ['Top', 'Middle', 'Bottom']
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _phPosition = val!),
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
          ),

          // --- TAB 5: NOTICES ---
          SingleChildScrollView(
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
          ),
          _buildAIDraftsTab(),
        ],
      ),
    );
  }

  Widget _buildAIDraftsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ai_drafts').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No AI drafts waiting."));
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            var type = data['type'] ?? 'social_media';
            
            if (type == 'blog_post') {
              return _buildBlogDraftCard(doc.id, data);
            } else {
              return _buildSocialDraftCard(doc.id, data);
            }
          },
        );
      },
    );
  }

  Widget _buildSocialDraftCard(String docId, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Social Media Campaign", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => FirebaseFirestore.instance.collection('ai_drafts').doc(docId).delete(),
                ),
              ],
            ),
            const Divider(),
            _buildDraftSection("Twitter Thread", data['twitter_draft'] ?? ''),
            const Divider(),
            _buildDraftSection("Reddit Post", data['reddit_draft'] ?? ''),
            const Divider(),
            _buildDraftSection("Substack Article", data['substack_draft'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogDraftCard(String docId, Map<String, dynamic> data) {
    String content = data['content'] ?? '';
    String topic = data['topic'] ?? 'Unknown Topic';
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("SEO Blog: $topic", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange))),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => FirebaseFirestore.instance.collection('ai_drafts').doc(docId).delete(),
                ),
              ],
            ),
            const Divider(),
            _buildDraftSection("Blog Content", content),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await FirebaseFirestore.instance.collection('blog_posts').add({
                    'topic': topic,
                    'content': content,
                    'created_at': FieldValue.serverTimestamp(),
                  });
                  await FirebaseFirestore.instance.collection('ai_drafts').doc(docId).delete();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Blog Post Published!"), backgroundColor: Colors.green));
                } catch (e) {
                  // ignore: empty_catches
                }
                setState(() => _isLoading = false);
              },
              icon: const Icon(Icons.publish),
              label: const Text("Publish to Website"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDraftSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title copied to clipboard!")));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text("Copy"),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(content, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

// ==========================================
// 🌟 AFFILIATE LINKS PAGE (HYBRID TABBED)
// ==========================================

