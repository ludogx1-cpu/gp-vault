import '../api_constants.dart';
import '../widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin/admin_ptc_tab.dart';
import 'admin/admin_affiliate_tab.dart';
import 'admin/admin_notice_tab.dart';
import 'admin/admin_reward_monitor_tab.dart';
import 'admin/admin_ai_drafts_tab.dart';
import 'admin/admin_chat_reports_tab.dart';
import 'admin/admin_dogbook_reports_tab.dart';
import 'admin/admin_subscribers_tab.dart';
import 'package:gp_faucet/src/brand_colors.dart';

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
    _adminTabController = TabController(length: 8, vsync: this);
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
        bottom: TabBar(
          controller: _adminTabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: kGold,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.ads_click), text: "Manage PTC Ads"),
            Tab(icon: Icon(Icons.handshake), text: "Affiliate Links"),
            Tab(icon: Icon(Icons.campaign), text: "Update Board"),
            Tab(icon: Icon(Icons.monitor_heart), text: "Reward Monitor"),
            Tab(icon: Icon(Icons.psychology), text: "AI Drafts"),
            Tab(icon: Icon(Icons.flag), text: "Chat Reports"),
            Tab(icon: Icon(Icons.pets), text: "Book Of Dog Reports"),
            Tab(icon: Icon(Icons.mail_outline), text: "Newsletter"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _adminTabController,
        children: const [
          AdminPtcTab(),
          AdminAffiliateTab(),
          AdminNoticeTab(),
          AdminRewardMonitorTab(),
          AdminAiDraftsTab(),
          AdminChatReportsTab(),
          AdminDogbookReportsTab(),
          AdminSubscribersTab(),
        ],
      ),
    );
  }
}
