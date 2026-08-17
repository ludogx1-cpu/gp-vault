import '../api_constants.dart';
import '../widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin/admin_ptc_tab.dart';
import 'admin/admin_affiliate_tab.dart';
import 'admin/admin_bonus_sponsors_tab.dart';
import 'admin/admin_html_snippets_tab.dart';
import 'admin/admin_notice_tab.dart';
import 'admin/admin_reward_monitor_tab.dart';
import 'admin/admin_ai_drafts_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _adminTabController;

  @override
  void initState() {
    super.initState();
    _adminTabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _adminTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != ApiConstants.adminUid) {
      return AppScaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return AppScaffold(
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
          TextButton.icon(
            icon: const Icon(Icons.visibility, color: Colors.white),
            label: const Text(
              "Preview Sponsors",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => launchUrl(Uri.parse('https://golden-paw-database.web.app/sponsors.html')),
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
            Tab(icon: Icon(Icons.monitor_heart), text: "Reward Monitor"),
            Tab(icon: Icon(Icons.psychology), text: "AI Drafts"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _adminTabController,
        children: const [
          AdminPtcTab(),
          AdminAffiliateTab(),
          AdminBonusSponsorsTab(),
          AdminHtmlSnippetsTab(),
          AdminNoticeTab(),
          AdminRewardMonitorTab(),
          AdminAiDraftsTab(),
        ],
      ),
    );
  }
}
