import '../widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DogeogotchaInstructionsPage extends StatelessWidget {
  const DogeogotchaInstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Dogeogotcha Instructions'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
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
              'Keep your pet happy and fed! Feeding costs 0.0001 DOGE, fully restores Hunger to 100%, and places a 24-hour investment that returns double (plus bonuses)!\n\nIf your pet gets too tired, click Sleep! It takes a 10-minute nap for FREE, recovers 50% Energy, and rewards you with 0.0001 DOGE when it wakes up. Sickness happens if any stat hits 0 for 3 days. Buy FREE medicine in the shop to cure it!',
            ),
            _buildSection(
              context,
              '🎾 Playing Fetch',
              'You can play fetch with your pet to increase its Happiness! Just click, hold, and drag the ball on the screen, then let go to throw it! Your pet will physically chase after the ball and bring it back to you. Playing fetch increases Happiness but costs 5% Hunger and 5% Energy.',
            ),
            _buildSection(
              context,
              '✋ Stroking Your Pet',
              'Give your pet some love! Just click on your pet and quickly wiggle your mouse pointer (or swipe your finger) back and forth over it to stroke it. Keep going until the green Attention bar completely fills up to increase its Attention stat!',
            ),
            _buildSection(
              context,
              '💤 Sleep Mode (Hiding your Pet)',
              'If you prefer to have a clean screen, you can click the "Power Button" icon on your pet to put it to sleep. When your pet is off and not roaming the screen, it will still automatically wake up when it needs a poo or a boop! Once you finish taking care of it, it will automatically go back to bed and disappear again.',
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
              'Your pet grows older over time! As it grows from a Baby to an Old Dog, it provides a passive aging multiplier that scales up your rewards for being a long-term owner.',
              style: TextStyle(fontSize: 14, height: 1.5, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
            ),
            const SizedBox(height: 15),
            _buildStageItem(context, 'Baby', '0 - 2 days', '+0% Bonus', 'assets/shiba_baby.png'),
            _buildStageItem(context, 'Toddler', '2 - 7 days', '+5% Bonus', 'assets/shiba_baby.png'),
            _buildStageItem(context, 'Puppy', '7 - 14 days', '+10% Bonus', 'assets/shiba_teen.png'),
            _buildStageItem(context, 'Child', '14 - 30 days', '+30% Bonus', 'assets/shiba_child.png'),
            _buildStageItem(context, 'Teen', '1 - 3 months', '+40% Bonus', 'assets/shiba_puppy.png'),
            _buildStageItem(context, 'Young Adult', '3 - 6 months', '+50% Bonus', 'assets/shiba_young_adult.png'),
            _buildStageItem(context, 'Adult', '6 - 12 months', '+75% Bonus', 'assets/shiba_adult.png'),
            _buildStageItem(context, 'Old Dog', '1 year+', '+100% Bonus (Max)', 'assets/old_dog.png'),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
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

