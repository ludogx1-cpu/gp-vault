import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../src/bitcotasks_service.dart';

class BitcoTasksNativeWidget extends StatefulWidget {
  final String subId;

  const BitcoTasksNativeWidget({super.key, required this.subId});

  @override
  State<BitcoTasksNativeWidget> createState() => _BitcoTasksNativeWidgetState();
}

class _BitcoTasksNativeWidgetState extends State<BitcoTasksNativeWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _categories = [
    'surveys', 'offers', 'ptc', 'shortlinks', 'faucet', 'video'
  ];

  final Map<String, List<dynamic>> _cachedData = {};
  final Map<String, bool> _isLoading = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadCategory(_categories[0]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    String category = _categories[_tabController.index];
    if (_cachedData[category] == null) {
      _loadCategory(category);
    }
  }

  Future<void> _loadCategory(String category) async {
    if (mounted) {
      setState(() {
        _isLoading[category] = true;
      });
    }

    try {
      final items = await BitcoTasksService.getOffers(widget.subId, category);
      if (mounted) {
        setState(() {
          _cachedData[category] = items;
          _isLoading[category] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedData[category] = [];
          _isLoading[category] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load $category: $e')),
        );
      }
    }
  }

  Future<void> _handleItemClick(String category, dynamic item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String? urlToOpen;

      if (category == 'surveys' || category == 'offers') {
        urlToOpen = item['link'];
      } else if (category == 'ptc') {
        final res = await BitcoTasksService.initTransaction(widget.subId, item['id'].toString(), 'ptc');
        urlToOpen = res['offer'];
      } else if (category == 'video') {
        final res = await BitcoTasksService.initTransaction(widget.subId, item['id'].toString(), 'video');
        urlToOpen = res['video_url'];
      } else if (category == 'shortlinks') {
        urlToOpen = await BitcoTasksService.getShortlink(widget.subId, item['id'].toString());
      } else if (category == 'faucet') {
        final id = item['id']?.toString() ?? item['hash']?.toString() ?? '';
        urlToOpen = BitcoTasksService.getFaucetClaimUrl(widget.subId, id);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (urlToOpen != null && urlToOpen.isNotEmpty) {
        final uri = Uri.parse(urlToOpen);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch URL';
        }
      } else {
        throw 'Invalid URL from provider';
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting task: $e')),
        );
      }
    }
  }

  Widget _buildTaskCard(String category, dynamic item) {
    final title = item['title'] ?? 'Task';
    final reward = item['reward']?.toString() ?? '0';
    final rewardName = item['reward_name'] ?? 'Coins';
    final description = item['description'] ?? item['requirements'] ?? '';
    final imageUrl = item['image'] ?? item['icon'];
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleItemClick(category, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon / Image
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.task, size: 60, color: Colors.grey),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getIconForCategory(category), color: Colors.blue, size: 30),
                ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+$reward $rewardName',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (item['duration'] != null)
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0),
                             child: Row(
                               children: [
                                 const Icon(Icons.timer, size: 14, color: Colors.grey),
                                 const SizedBox(width: 4),
                                 Text('${item['duration']}s', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                               ],
                             ),
                           )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Center(
                child: Icon(Icons.chevron_right, color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch(category) {
      case 'surveys': return Icons.poll;
      case 'offers': return Icons.local_offer;
      case 'ptc': return Icons.mouse;
      case 'video': return Icons.play_circle;
      case 'shortlinks': return Icons.link;
      case 'faucet': return Icons.water_drop;
      default: return Icons.task;
    }
  }

  Widget _buildListForCategory(String category) {
    if (_isLoading[category] ?? true) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _cachedData[category] ?? [];
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconForCategory(category), size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No ${category.toUpperCase()} available right now.',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCategory(category),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(category, items[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: _categories.map((c) => Tab(text: c.toUpperCase())).toList(),
        ),
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((c) => _buildListForCategory(c)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
