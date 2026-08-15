import 'package:flutter/material.dart';
import '../../../src/theme_provider.dart';
import '../../create_ad_page.dart';
import '../../../widgets/widgets.dart';

class CampaignCard extends StatelessWidget {
  final bool isDark;
  final ThemeProvider themeProvider;

  const CampaignCard({
    super.key,
    required this.isDark,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? themeProvider.darkGreyBorder : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Ready to Promote?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateAdPage(),
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch, color: Colors.white),
              label: const Text(
                "LAUNCH NEW CAMPAIGN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VaultSwapCard extends StatelessWidget {
  final bool isDark;
  final ThemeProvider themeProvider;
  final double dogeBalance;
  final TextEditingController swapAmountController;
  final bool isSwapping;
  final VoidCallback onSwap;

  const VaultSwapCard({
    super.key,
    required this.isDark,
    required this.themeProvider,
    required this.dogeBalance,
    required this.swapAmountController,
    required this.isSwapping,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? themeProvider.darkGreyBorder : Colors.amber.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_horizontal_circle,
                color: isDark ? Colors.amber : Colors.black87,
              ),
              const SizedBox(width: 10),
              Text(
                "Instant Vault Swap",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "Balance: ${dogeBalance.toStringAsFixed(4)} DOGE",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.amber.shade200 : Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: swapAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: "DOGE to Convert",
              labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              enabledBorder: isDark
                  ? const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    )
                  : null,
              hintText: "1.0",
              hintStyle: TextStyle(color: isDark ? Colors.white30 : null),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "⚠️ Includes a tiny 1% exchange fee",
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSwapping ? null : onSwap,
              icon: const Icon(Icons.bolt),
              label: Text(
                isSwapping ? "Converting..." : "SWAP FOR AD CREDIT",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.amber : Colors.black87,
                foregroundColor: isDark ? Colors.white : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DepositWarningCard extends StatelessWidget {
  final bool isDark;
  final ThemeProvider themeProvider;

  const DepositWarningCard({
    super.key,
    required this.isDark,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.red.shade50,
        border: Border.all(
          color: isDark ? Colors.red.shade900 : Colors.red.shade200,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 30,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "IMPORTANT: Funds deposited here are strictly for purchasing advertising. They CANNOT be staked, transferred, or withdrawn back to FaucetPay.",
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdBalanceCard extends StatelessWidget {
  final bool isDark;
  final ThemeProvider themeProvider;
  final double adsBalance;
  final VoidCallback onDeposit;

  const AdBalanceCard({
    super.key,
    required this.isDark,
    required this.themeProvider,
    required this.adsBalance,
    required this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? themeProvider.darkGreyBorder : Colors.green.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Advertising Balance",
            style: TextStyle(
              fontSize: 16,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "\$${adsBalance.toStringAsFixed(2)} USDT",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.green.shade300 : Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDeposit,
              icon: const Icon(Icons.add_circle, color: Colors.white),
              label: const Text(
                "DEPOSIT USDT",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdStoreList extends StatelessWidget {
  final bool isDark;
  final ThemeProvider themeProvider;
  final double adsBalance;
  final Function(double, String, String, double) onBuyAd;
  final Function(double) onBuyPtcAd;

  const AdStoreList({
    super.key,
    required this.isDark,
    required this.themeProvider,
    required this.adsBalance,
    required this.onBuyAd,
    required this.onBuyPtcAd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedHoverCard(
          backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isDark ? Border.all(color: themeProvider.darkGreyBorder) : null,
          child: ListTile(
            leading: const Icon(Icons.image, color: Colors.purple, size: 30),
            title: Text(
              "Global Top Banner",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : null,
              ),
            ),
            subtitle: Text(
              "Top of Faucet page (7 Days).",
              style: TextStyle(color: isDark ? Colors.white70 : null),
            ),
            trailing: const Text(
              "\$3.50",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            onTap: () => onBuyAd(adsBalance, 'global_banner', 'Global Banner', 3.5),
          ),
        ),
        AnimatedHoverCard(
          backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isDark ? Border.all(color: themeProvider.darkGreyBorder) : null,
          child: ListTile(
            leading: const Icon(Icons.check_box_outline_blank, color: Colors.blue, size: 30),
            title: Text(
              "Square Ad (Left)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : null,
              ),
            ),
            subtitle: Text(
              "Next to Claim Button (7 Days).",
              style: TextStyle(color: isDark ? Colors.white70 : null),
            ),
            trailing: const Text(
              "\$1.75",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            onTap: () => onBuyAd(adsBalance, 'square_left', 'Left Square Ad', 1.75),
          ),
        ),
        AnimatedHoverCard(
          backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isDark ? Border.all(color: themeProvider.darkGreyBorder) : null,
          child: ListTile(
            leading: const Icon(Icons.check_box_outline_blank, color: Colors.blue, size: 30),
            title: Text(
              "Square Ad (Right)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : null,
              ),
            ),
            subtitle: Text(
              "Next to Claim Button (7 Days).",
              style: TextStyle(color: isDark ? Colors.white70 : null),
            ),
            trailing: const Text(
              "\$1.75",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            onTap: () => onBuyAd(adsBalance, 'square_right', 'Right Square Ad', 1.75),
          ),
        ),
        AnimatedHoverCard(
          backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isDark ? Border.all(color: themeProvider.darkGreyBorder) : null,
          child: ListTile(
            leading: const Icon(Icons.ad_units, color: Colors.red, size: 30),
            title: Text(
              "Interstitial Pop-up",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : null,
              ),
            ),
            subtitle: Text(
              "Shows during claim loading (7 Days).",
              style: TextStyle(color: isDark ? Colors.white70 : null),
            ),
            trailing: const Text(
              "\$7.00",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            onTap: () => onBuyAd(adsBalance, 'interstitial', 'Interstitial Pop-up', 7.0),
          ),
        ),
        AnimatedHoverCard(
          backgroundColor: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isDark ? Border.all(color: themeProvider.darkGreyBorder) : null,
          child: ListTile(
            leading: const Icon(Icons.ads_click, color: Colors.orange, size: 30),
            title: Text(
              "Buy PTC Clicks",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : null,
              ),
            ),
            subtitle: Text(
              "Select your duration & volume.",
              style: TextStyle(color: isDark ? Colors.white70 : null),
            ),
            trailing: const Text(
              "Custom",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            onTap: () => onBuyPtcAd(adsBalance),
          ),
        ),
      ],
    );
  }
}
