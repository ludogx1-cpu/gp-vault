import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../widgets/widgets.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class FAQPage extends StatelessWidget {
  const FAQPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const ExpansionTile(
                  title: Text(
                    "What is Golden Paw?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Golden Paw is a premier Dogecoin reward platform and advertising network. Users can earn free DOGE by claiming from our faucet or viewing sponsored PTC (Paid-To-Click) ads. Advertisers can purchase high-quality crypto traffic.",
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    "How do I withdraw my earnings?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Once you reach the minimum withdrawal threshold of 0.001 DOGE in your Vault, you can navigate to your Profile, enter your FaucetPay Dogecoin address, and initiate an instant withdrawal.",
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    "Can I use a VPN or Proxy?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "Absolutely not. The use of VPNs, Proxies, Tor nodes, or automated claiming bots is strictly prohibited. Our security systems will automatically flag and permanently ban any accounts caught using these methods.",
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    "How does Staking work?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        "You can lock your available DOGE into the Vault to earn an 8.5% Annual Percentage Yield (APY). Interest is calculated and distributed every single second.",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


