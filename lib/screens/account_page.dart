import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../src/user_provider.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';
import '../widgets/universal_web_view/universal_web_view.dart';
import 'account/account_profile_card.dart';
import 'account/account_withdraw_card.dart';
import 'account/account_bank_card.dart';
import 'account/account_history_card.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = FirebaseAuth.instance.currentUser;
          return Stack(
            children: [
              PageWithFooter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (kIsWeb) const SizedBox(height: 80), // Push ads below the app header
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: 728,
                              height: 90,
                              child: UniversalWebView.create(viewType: 'adsterra-728x90', width: 728, height: 90),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const BitcotasksAdWidget(),
                          const SizedBox(height: 20),
                          Image.asset(
                            'assets/Goldenpawicon.png',
                            width: 130,
                            height: 130,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),

                          if (user == null) ...[
                            Text(
                              "Not Logged In",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: gpBrownText(context, darkColor: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Create a Golden Paw account to unlock the full ecosystem.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            const SizedBox(height: 30),
                            ListenableBuilder(
                              listenable: themeProvider,
                              builder: (context, _) {
                                final isDark = themeProvider.isDarkMode;
                                return AnimatedHoverCard(
                                  backgroundColor: isDark
                                      ? Colors.grey.shade900
                                      : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.amber,
                                    width: 0.5,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: const Icon(
                                            Icons.account_balance_wallet,
                                            color: Colors.amber,
                                            size: 28,
                                          ),
                                          title: Text(
                                            "Save Your Doge",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "Store claims internally instead of instantly sending to FaucetPay.",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.bolt,
                                            color: Colors.amber,
                                            size: 28,
                                          ),
                                          title: Text(
                                            "Earn Staking Rewards",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "Lock your saved Doge in the Vault to earn daily interest.",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => showAuthDialogGlobal(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  "LOG IN",
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () => showAuthDialogGlobal(context, false),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.amber.shade700,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  "CREATE ACCOUNT",
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Builder(
                              builder: (context) {
                                double vaultBalance = 0.0;
                                double bankBalance = 0.0;
                                double offerwallBalance = 0.0;
                                final userData = userProvider.userData;
                                if (userData != null) {
                                  vaultBalance = (userData['doge_balance'] ?? 0.0).toDouble();
                                  bankBalance = (userData['bank_balance'] ?? 0.0).toDouble();
                                  offerwallBalance = (userData['offerwall_balance'] ?? 0.0).toDouble();
                                }

                                return Column(
                                  children: [
                                    const Text(
                                      "Welcome back!",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      user.email ?? "Unknown Doge",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: gpBrownText(
                                          context,
                                          darkColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    ListenableBuilder(
                                      listenable: themeProvider,
                                      builder: (context, _) {
                                        final isDark = themeProvider.isDarkMode;
                                        return AccountProfileCard(
                                          isDark: isDark,
                                          currentUsername: userData?['username'] ?? userData?['chat_username'] ?? 'Anonymous',
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    ListenableBuilder(
                                      listenable: themeProvider,
                                      builder: (context, _) {
                                        final isDark = themeProvider.isDarkMode;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.grey.shade900
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Colors.amber,
                                              width: 0.5,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(
                                              Icons.security,
                                              color: Colors.green,
                                            ),
                                            title: Text(
                                              "Two-Factor Auth (2FA)",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "Protect your Vault balance",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black87,
                                              ),
                                            ),
                                            trailing: Switch(
                                              value: _twoFactorEnabled,
                                              activeThumbColor: Colors.green,
                                              onChanged: (val) {
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text("2FA Setup coming soon!"),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 25),
                                    
                                    ListenableBuilder(
                                      listenable: themeProvider,
                                      builder: (context, _) {
                                        return AccountWithdrawCard(
                                          isDark: themeProvider.isDarkMode,
                                          currentBalance: vaultBalance,
                                        );
                                      },
                                    ),
                                    
                                    const SizedBox(height: 25),
                                    
                                    ListenableBuilder(
                                      listenable: themeProvider,
                                      builder: (context, _) {
                                        return AccountBankCard(
                                          isDark: themeProvider.isDarkMode,
                                          bankBalance: bankBalance,
                                          vaultBalance: vaultBalance,
                                          offerwallBalance: offerwallBalance,
                                        );
                                      },
                                    ),
                                    
                                    const SizedBox(height: 25),
                                    
                                    ListenableBuilder(
                                      listenable: themeProvider,
                                      builder: (context, _) {
                                        return AccountHistoryCard(
                                          isDark: themeProvider.isDarkMode,
                                          userData: userData,
                                        );
                                      },
                                    ),
                                    
                                    const SizedBox(height: 25),
                                    
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          try {
                                            await GoogleSignIn().signOut();
                                          } catch (_) {}
                                          await FirebaseAuth.instance.signOut();
                                        },
                                        icon: const Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          "LOG OUT",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 30),
                          const PwaInstallWidget(),
                          const SizedBox(height: 30),
                          const EnableNotificationsWidget(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width >= 1000) ...[
                Positioned(
                  left: ((MediaQuery.of(context).size.width - 800) / 2 - 160) / 2,
                  top: 100,
                  width: 160,
                  height: 600,
                  child: UniversalWebView.create(viewType: 'adsterra-160x600', width: 160, height: 600),
                ),
                Positioned(
                  right: ((MediaQuery.of(context).size.width - 800) / 2 - 160) / 2,
                  top: 100,
                  width: 160,
                  height: 300,
                  child: UniversalWebView.create(viewType: 'adsterra-160x300', width: 160, height: 300),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
