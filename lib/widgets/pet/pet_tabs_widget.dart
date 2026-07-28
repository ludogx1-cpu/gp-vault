import 'package:flutter/material.dart';

/// The data model passed into the pet tabs so it stays stateless.
class PetTabsData {
  final String stage;
  final bool isDark;
  final List<String> ownedAccessories;
  final List<String> equippedAccessories;
  final List<String> ownedTricks;
  final Map<String, int> ownedConsumables;
  final List<String> ownedBalls;
  final String equippedBall;

  const PetTabsData({
    required this.stage,
    required this.isDark,
    required this.ownedAccessories,
    required this.equippedAccessories,
    required this.ownedTricks,
    required this.ownedConsumables,
    required this.ownedBalls,
    required this.equippedBall,
  });
}

/// Callbacks fired from within the tab views so the parent state can respond.
class PetTabsCallbacks {
  final void Function(String id, bool equip) onEquipAccessory;
  final void Function(String id, double price) onBuyAccessory;
  final void Function(String id) onUseConsumable;
  final void Function(String id, double price) onBuyConsumable;
  final void Function(String color) onEquipBall;
  final void Function(String color, double price) onBuyBall;
  final void Function(String name) onPerformTrick;
  final void Function(String name, double price) onBuyTrick;

  const PetTabsCallbacks({
    required this.onEquipAccessory,
    required this.onBuyAccessory,
    required this.onUseConsumable,
    required this.onBuyConsumable,
    required this.onEquipBall,
    required this.onBuyBall,
    required this.onPerformTrick,
    required this.onBuyTrick,
  });
}

/// The tabbed area inside [ShibaPetWidget]: Info, Shop, Items, Balls, Tricks.
class PetTabsWidget extends StatelessWidget {
  final PetTabsData data;
  final PetTabsCallbacks callbacks;

  const PetTabsWidget({
    super.key,
    required this.data,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Container(
        height: 180,
        margin: const EdgeInsets.only(top: 15),
        decoration: BoxDecoration(
          color: data.isDark
              ? Colors.blueGrey.withValues(alpha: 0.2)
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            TabBar(
              labelColor: data.isDark ? Colors.amber : Colors.blue.shade800,
              unselectedLabelColor:
                  data.isDark ? Colors.white54 : Colors.black54,
              indicatorColor: Colors.amber,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.info, size: 20), text: 'Info'),
                Tab(icon: Icon(Icons.shopping_cart, size: 20), text: 'Shop'),
                Tab(icon: Icon(Icons.fastfood, size: 20), text: 'Items'),
                Tab(
                    icon: Icon(Icons.sports_baseball, size: 20),
                    text: 'Balls'),
                Tab(icon: Icon(Icons.star, size: 20), text: 'Tricks'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInfoTab(),
                  _buildShopTab(),
                  _buildConsumablesTab(),
                  _buildBallsTab(),
                  _buildTricksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Info ─────────────────────────────────────────────────────────────────
  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Text(
          '• Stroke: Stroke your pet to raise Attention & get 5 XP!\n'
          '• Fetch: Swipe the ball! Costs Energy & Hunger but boosts Happiness.\n'
          '• Boop: Every 30 mins, it walks to the camera. Boop its nose for 0.002 DOGE!\n'
          '• Walk: Walk your pet every 3 hours for up to 0.005 DOGE.\n'
          '• Sickness: Keep stats above 0! Sick pets can\'t walk and lose faucet bonuses.\n'
          '• Items: Buy Medicine to cure sickness for FREE.',
          style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: data.isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  // ─── Shop ─────────────────────────────────────────────────────────────────
  Widget _buildShopTab() {
    if (data.stage == 'egg') {
      return const Center(
          child: Text(
              'Shop unlocks at Baby stage!\n(Wait 2 days or use Admin controls)',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)));
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildShopItem('top_hat', 'Fancy Top Hat', 1.0, '+10% PTC Bonus'),
        _buildShopItem('sunglasses', 'Cool Shades', 2.0, '+20% PTC Bonus'),
        _buildShopItem('gold_chain', 'Gold Chain', 3.0, '+30% PTC Bonus'),
        _buildShopItem(
            'diamond_watch', 'Diamond Watch', 5.0, '+50% PTC Bonus'),
        _buildShopItem('crown', 'Royal Crown', 10.0, '+100% PTC Bonus'),
        _buildShopItem('coat_basic', 'Basic Coat', 1.5, '+15% PTC Bonus'),
        _buildShopItem('coat_rain', 'Rain Coat', 2.5, '+25% PTC Bonus'),
        _buildShopItem('coat_winter', 'Winter Coat', 4.0, '+40% PTC Bonus'),
        _buildShopItem(
            'coat_luxury', 'Luxury Coat', 7.5, '+75% PTC Bonus'),
      ],
    );
  }

  Widget _buildShopItem(
      String id, String name, double price, String bonus) {
    final isOwned = data.ownedAccessories.contains(id);
    final isEquipped = data.equippedAccessories.contains(id);

    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Image.asset('assets/shiba_$id.png',
          width: 30,
          height: 30,
          errorBuilder: (c, e, s) => const Icon(Icons.checkroom)),
      title: Text(name,
          style:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: isOwned
          ? Text(bonus,
              style: const TextStyle(fontSize: 10, color: Colors.green))
          : Text('\$$price USDT (Ad Credit)\n$bonus',
              style: const TextStyle(fontSize: 10, color: Colors.amber)),
      trailing: isOwned
          ? ElevatedButton(
              onPressed: () => callbacks.onEquipAccessory(id, !isEquipped),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEquipped ? Colors.grey : Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: Text(isEquipped ? 'Unequip' : 'Equip',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white)),
            )
          : ElevatedButton(
              onPressed: () => callbacks.onBuyAccessory(id, price),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: const Text('Buy',
                  style: TextStyle(fontSize: 10, color: Colors.black)),
            ),
    );
  }

  // ─── Consumables ──────────────────────────────────────────────────────────
  Widget _buildConsumablesTab() {
    if (data.stage == 'egg') {
      return const Center(
          child: Text(
              'Items unlock at Baby stage!\n(Wait 2 days or use Admin controls)',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)));
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildConsumableItem(
            'medicine', 'Medicine', 0.0, 'Cures Sickness (FREE)', Icons.local_hospital),
      ],
    );
  }

  Widget _buildConsumableItem(
      String id, String name, double price, String desc, IconData icon) {
    final count = data.ownedConsumables[id] ?? 0;

    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 30, color: Colors.amber),
      title: Text(name,
          style:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: Text('Owned: $count\n$desc',
          style: const TextStyle(fontSize: 10, color: Colors.grey)),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (count > 0)
            ElevatedButton(
              onPressed: () => callbacks.onUseConsumable(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(50, 30),
              ),
              child: const Text('Use',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
          ElevatedButton(
            onPressed: () => callbacks.onBuyConsumable(id, price),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(50, 30),
            ),
            child: Text(price == 0.0 ? 'FREE' : '\$$price',
                style:
                    const TextStyle(fontSize: 10, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // ─── Balls ────────────────────────────────────────────────────────────────
  Widget _buildBallsTab() {
    if (data.stage == 'egg') {
      return const Center(
          child: Text('Balls unlock at Baby stage!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)));
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildBallItem('white', 'Classic White', 0.0, '0.0 DOGE | 1 XP'),
        _buildBallItem('red', 'Red Ball', 0.25, '0.0001 DOGE | 1 XP'),
        _buildBallItem(
            'orange', 'Orange Ball', 0.75, '0.0002 DOGE | 2 XP'),
        _buildBallItem(
            'yellow', 'Yellow Ball', 1.25, '0.0003 DOGE | 3 XP'),
        _buildBallItem(
            'green', 'Green Ball', 1.75, '0.0004 DOGE | 4 XP'),
        _buildBallItem(
            'blue', 'Blue Ball', 2.25, '0.0005 DOGE | 5 XP'),
        _buildBallItem(
            'indigo', 'Indigo Ball', 2.75, '0.0006 DOGE | 6 XP'),
        _buildBallItem(
            'violet', 'Violet Ball', 3.25, '0.0007 DOGE | 7 XP'),
      ],
    );
  }

  Widget _buildBallItem(
      String color, String name, double price, String bonus) {
    final isOwned = data.ownedBalls.contains(color);
    final isEquipped = data.equippedBall == color;

    Color ballColor = Colors.white;
    switch (color) {
      case 'red':
        ballColor = Colors.red;
        break;
      case 'orange':
        ballColor = Colors.orange;
        break;
      case 'yellow':
        ballColor = Colors.yellow;
        break;
      case 'green':
        ballColor = Colors.green;
        break;
      case 'blue':
        ballColor = Colors.blue;
        break;
      case 'indigo':
        ballColor = Colors.indigo;
        break;
      case 'violet':
        ballColor = Colors.purple;
        break;
    }

    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
              color: ballColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black))),
      title: Text(name,
          style:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      subtitle: isOwned
          ? Text(bonus,
              style: const TextStyle(fontSize: 10, color: Colors.green))
          : Text('\$$price USDT (Ad Credit)\n$bonus',
              style: const TextStyle(fontSize: 10, color: Colors.amber)),
      trailing: isOwned
          ? ElevatedButton(
              onPressed: isEquipped ? null : () => callbacks.onEquipBall(color),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEquipped ? Colors.grey : Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: Text(isEquipped ? 'Equipped' : 'Equip',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white)),
            )
          : ElevatedButton(
              onPressed: () => callbacks.onBuyBall(color, price),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(60, 30),
              ),
              child: const Text('Buy',
                  style: TextStyle(fontSize: 10, color: Colors.black)),
            ),
    );
  }

  // ─── Tricks ───────────────────────────────────────────────────────────────
  Widget _buildTricksTab() {
    if (data.stage == 'egg') {
      return const Center(
          child: Text(
              'Tricks unlock at Baby stage!\n(Wait 2 days or use Admin controls)',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)));
    }
    return Center(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _buildTrickButton('Spin', Icons.rotate_right, 1.0, '+10% Sponsor Bonus'),
            _buildTrickButton('Jump', Icons.arrow_upward, 2.0, '+20% Sponsor Bonus'),
            _buildTrickButton('Roll Over', Icons.replay, 3.0, '+30% Sponsor Bonus'),
            _buildTrickButton('Backflip', Icons.loop, 5.0, '+50% Sponsor Bonus'),
            _buildTrickButton(
                'Moonwalk', Icons.directions_walk, 10.0, '+100% Sponsor Bonus'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrickButton(
      String name, IconData icon, double price, String bonus) {
    final isOwned = data.ownedTricks.contains(name);
    return Tooltip(
      message: isOwned
          ? 'Perform $name'
          : 'Buy $name for \$$price USDT / ${price * 8.0} DOGE ($bonus)',
      child: ElevatedButton.icon(
        onPressed: () {
          if (isOwned) {
            callbacks.onPerformTrick(name);
          } else {
            callbacks.onBuyTrick(name, price);
          }
        },
        icon: Icon(isOwned ? icon : Icons.lock, size: 16),
        label: Text(isOwned ? name : 'Buy'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isOwned ? Colors.purple.shade400 : Colors.grey.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
