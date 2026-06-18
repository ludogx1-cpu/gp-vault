import 'package:flutter/material.dart';

class DogeogotchaInstructionsPage extends StatelessWidget {
  const DogeogotchaInstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dogeogotcha Instructions'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.pets, size: 80, color: Colors.amber),
            ),
            const SizedBox(height: 20),
            Text(
              'How to play Dogeogotcha',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            _buildSection(
              context,
              'Welcome to Dogeogotcha!',
              'Your Dogeogotcha is your virtual pet that earns you extra DOGE! As your pet grows, you unlock new ways to boost your earnings across the platform.',
            ),
            _buildSection(
              context,
              '❤️ Happiness, 🍗 Hunger, ⚡ Energy',
              'Keep your pet happy and fed! Feeding, Playing, or Sleeping costs 0.0001 DOGE, but fully restores that stat to 100% and places a 24-hour investment that returns double (plus bonuses)! You can only perform each action once every 5 hours. Stats decay by 25% every 5 hours, so keep them above 80% to ensure you get the maximum possible bonus on your investments.',
            ),
            _buildSection(
              context,
              '🎒 The Shop & PTC Rewards',
              'Once your pet reaches the Baby stage, you unlock the Shop! Use your Ad Credit (USDT) to buy premium accessories.\n\n'
              'Equipping accessories directly boosts your Pay-To-Click (PTC) ad rewards. You can equip up to 3 items at the same time. The total bonus of all equipped items multiplies your PTC rewards. (E.g., Crown + Watch = 150% extra!)',
            ),
            _buildSection(
              context,
              '🤸 Tricks & Sponsor Bonuses',
              'Once your pet reaches the Baby stage, you can buy Tricks! Command your pet to perform them to receive an "Active Buff".\n\n'
              'Active Trick Buffs directly boost the rewards you get from clicking Visit Bonus Sponsors! (E.g., Moonwalk = +100% Sponsor Bonus!)',
            ),
            const SizedBox(height: 15),
            Text(
              '🐾 Growth Stages & Rewards',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
              )
            ),
            const SizedBox(height: 10),
            Text(
              'Your pet grows older over time! As it grows from an Egg to an Adult, it provides a passive aging multiplier that scales up your rewards for being a long-term owner.',
              style: TextStyle(fontSize: 14, height: 1.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
            ),
            const SizedBox(height: 15),
            _buildStageItem(context, 'Egg', '0 - 2 days', '+0% Bonus', 'assets/shiba_egg.png'),
            _buildStageItem(context, 'Baby', '2 - 7 days', '+5% Bonus', 'assets/shiba_baby.png'),
            _buildStageItem(context, 'Toddler', '7 - 14 days', '+10% Bonus', 'assets/shiba_baby.png'),
            _buildStageItem(context, 'Puppy', '14 - 30 days', '+30% Bonus', 'assets/shiba_teen.png'),
            _buildStageItem(context, 'Child', '1 - 3 months', '+40% Bonus', 'assets/shiba_child.png'),
            _buildStageItem(context, 'Teen', '3 - 6 months', '+50% Bonus', 'assets/shiba_puppy.png'),
            _buildStageItem(context, 'Young Adult', '6 - 12 months', '+75% Bonus', 'assets/shiba_young_adult.png'),
            _buildStageItem(context, 'Adult', '1 year+', '+100% Bonus (Max)', 'assets/shiba_adult.png'),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Back to Golden Paw', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
          const SizedBox(height: 5),
          Text(content, style: TextStyle(fontSize: 14, height: 1.5, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildStageItem(BuildContext context, String title, String age, String reward, String assetPath) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.amber.shade300 : Colors.amber.shade800;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(5),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
                const SizedBox(height: 2),
                Text('Age: $age', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                Text('Reward: $reward', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
