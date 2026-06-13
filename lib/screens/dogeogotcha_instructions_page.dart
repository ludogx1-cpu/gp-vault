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
              'Your Dogeogotcha is your virtual pet that earns you extra DOGE from the faucet! Taking care of your pet and buying it items increases your Faucet multiplier.',
            ),
            _buildSection(
              context,
              '❤️ Happiness, 🍗 Hunger, ⚡ Energy',
              'Keep your pet happy and fed! You can feed your pet, play with it, or put it to sleep to restore its stats. Every day, its stats will naturally decay. If any stat drops to 0, you lose the multiplier from the pet completely! Keep them above 80% to ensure you get the maximum possible multiplier.',
            ),
            _buildSection(
              context,
              '🎒 The Shop & Equipping Items',
              'Use your Ad Credit (USDT) to buy premium accessories!\n\n'
              '• Sunglasses (+10%)\n'
              '• Top Hat (+20%)\n'
              '• Gold Chain (+30%)\n'
              '• Royal Crown (+50%)\n'
              '• Diamond Watch (+100%)\n\n'
              'You can also purchase Coats ranging from +15% to +75% bonus!\n\n'
              'You can equip up to 3 items at the same time. The total bonus of all equipped items directly multiplies your daily Faucet rewards. (E.g., Crown + Watch = 150% extra!)',
            ),
            _buildSection(
              context,
              '🤸 Tricks & Active Buffs',
              'Buy tricks from the Shop and command your pet to perform them! Each time your pet performs a trick, it receives an "Active Buff".\n\n'
              '• Sit (+10%)\n'
              '• Spin (+20%)\n'
              '• Roll Over (+40%)\n'
              '• Backflip (+100%)\n\n'
              'When you claim the Faucet, all your Active Buffs are consumed to give you a massive temporary multiplier on that claim! You must perform the tricks again before your next claim to get the buff again.',
            ),
            _buildSection(
              context,
              '🐾 Growth Stages',
              'Your pet grows older over time! As it grows from a Baby to a Teen to an Adult, it provides a passive aging multiplier that scales up your rewards for being a long-term owner.',
            ),
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
    final titleColor = isDark ? Colors.white : Colors.brown;
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
}
