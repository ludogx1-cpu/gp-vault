import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../src/theme_provider.dart';
import '../../widgets/widgets.dart';
import 'package:gp_faucet/src/brand_colors.dart';
import 'dogbook_api.dart';
import 'dogbook_session.dart';
import 'dogbook_sheets.dart';
import 'dogbook_widgets.dart';

export 'dogbook_widgets.dart' show timeAgo;

/// The Book Of Dog: Golden Paw's social feed for dogs.
///
/// "For you" shows everyone's posts, newest first. "Following" shows posts
/// from the dogs you follow. Reads come straight from Firestore; every change
/// goes through the moderated backend (DogbookApi).
class BookOfDogPage extends StatefulWidget {
  const BookOfDogPage({super.key});

  @override
  State<BookOfDogPage> createState() => _BookOfDogPageState();
}

class _BookOfDogPageState extends State<BookOfDogPage> {
  static const int _pageSize = 20;
  int _limit = _pageSize;
  bool _following = false;

  // Following tab: one-off load, refreshed on demand.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>? _followingFeed;
  String _followingKey = '';

  DogbookSession get _s => DogbookSession.instance;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadFollowing(List<String> dogIds, int limit) async {
    final fs = FirebaseFirestore.instance;
    final all = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (var i = 0; i < dogIds.length && i < 90; i += 30) {
      final chunk = dogIds.sublist(i, (i + 30).clamp(0, dogIds.length));
      final snap = await fs
          .collection('dogbook_posts')
          .where('dog_id', whereIn: chunk)
          .where('hidden', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      all.addAll(snap.docs);
    }
    DateTime t(QueryDocumentSnapshot<Map<String, dynamic>> d) => tsDate(d.data()['created_at']) ?? DateTime(2000);
    all.sort((a, b) => t(b).compareTo(t(a)));
    return all.take(limit).toList();
  }

  Future<void> _unblockAll() async {
    final list = List<String>.from(_s.blocked);
    for (final uid in list) {
      final r = await DogbookApi.setBlocked(uid, false);
      if (!r.ok) {
        if (mounted) dogbookSnack(context, r.error);
        return;
      }
    }
    if (mounted) dogbookSnack(context, 'Everyone you hid is showing again.');
  }

  void _reshare(String id, Map<String, dynamic> post) {
    openComposer(context, reshareOf: id, resharePreview: post);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(),
      body: ListenableBuilder(
        listenable: Listenable.merge([themeProvider, _s]),
        builder: (context, _) {
          final isDark = themeProvider.isDarkMode;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _header(isDark)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    sliver: SliverToBoxAdapter(child: _tabs()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: _following ? _followingList() : _forYouList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tabs() {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(selectedBackgroundColor: kGold, selectedForegroundColor: Colors.black),
      segments: const [
        ButtonSegment(value: false, label: Text('For you'), icon: Icon(Icons.public)),
        ButtonSegment(value: true, label: Text('Following'), icon: Icon(Icons.favorite_outline)),
      ],
      selected: {_following},
      onSelectionChanged: (v) => setState(() {
        _following = v.first;
        _limit = _pageSize;
        _followingFeed = null;
      }),
    );
  }

  Widget _message(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ),
      );

  Widget _postList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, bool mayHaveMore) {
    final visible = docs.where((d) => !_s.blocked.contains(d.data()['uid'])).toList();
    return SliverList.list(
      children: [
        for (final d in visible)
          PostCard(
            id: d.id,
            post: d.data(),
            onComments: () => openComments(context, d.id, (d.data()['dog_name'] ?? '').toString()),
            onReshare: () => _reshare(d.id, d.data()),
            onDeleted: () => setState(() => _followingFeed = null),
          ),
        if (mayHaveMore)
          Center(
            child: OutlinedButton(
              onPressed: () => setState(() {
                _limit += _pageSize;
                _followingFeed = null;
              }),
              child: const Text('Show more'),
            ),
          ),
      ],
    );
  }

  Widget _forYouList() {
    final query = FirebaseFirestore.instance
        .collection('dogbook_posts')
        .where('hidden', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .limit(_limit);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return _message('The Book Of Dog could not load. Please try again in a moment.');
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _message('No posts yet. Be the first to share your dog! 🐶');
        return _postList(docs, docs.length >= _limit);
      },
    );
  }

  Widget _followingList() {
    if (!_s.signedIn) return _message('Sign in to follow dogs and see their posts here.');
    final ids = _s.following.toList()..sort();
    if (ids.isEmpty) return SliverToBoxAdapter(child: _suggestions());
    final key = '${ids.join(',')}|$_limit';
    if (_followingFeed == null || key != _followingKey) {
      _followingKey = key;
      _followingFeed = _loadFollowing(ids, _limit);
    }
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: _followingFeed,
      builder: (context, snap) {
        if (snap.hasError) return _message('Could not load posts from the dogs you follow.');
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())));
        }
        if (snap.data!.isEmpty) return _message("The dogs you follow haven't posted yet.");
        return _postList(snap.data!, snap.data!.length >= _limit);
      },
    );
  }

  /// Popular dogs to follow, for people who don't follow anyone yet.
  Widget _suggestions() {
    final query = FirebaseFirestore.instance
        .collection('dogbook_dogs')
        .where('hidden', isEqualTo: false)
        .orderBy('follower_count', descending: true)
        .limit(12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text("You're not following any dogs yet. Here are some to say hello to:",
              style: TextStyle(color: Colors.grey)),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snap) {
            final docs = (snap.data?.docs ?? const [])
                .where((d) => d.data()['owner_uid'] != _s.user?.uid)
                .toList();
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            if (docs.isEmpty) {
              return const Text('No dog profiles yet. Add yours with "My dogs" above!',
                  style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: [
                for (final d in docs) DogListTile(id: d.id, dog: d.data()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _header(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGold.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets, color: kGold, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('The Book Of Dog',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              if (_s.signedIn)
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/book-of-dog/notifications'),
                  icon: Badge(
                    isLabelVisible: _s.unread > 0,
                    label: Text(_s.unread > 98 ? '99+' : '${_s.unread}'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 'rules') context.push('/book-of-dog/rules');
                  if (v == 'dogs') context.push('/book-of-dog/my-dogs');
                  if (v == 'unblock') _unblockAll();
                },
                itemBuilder: (_) => [
                  if (_s.signedIn) const PopupMenuItem(value: 'dogs', child: Text('My dogs')),
                  const PopupMenuItem(value: 'rules', child: Text('Book Of Dog rules')),
                  if (_s.signedIn && _s.blocked.isNotEmpty)
                    PopupMenuItem(value: 'unblock', child: Text('Show the ${_s.blocked.length} people I hid')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Share your dog with other dog lovers. Be kind, dogs only. 🐾',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Write a post', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => openComposer(context),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  side: const BorderSide(color: kGold),
                ),
                icon: const Icon(Icons.pets, color: kGold),
                label: const Text('My dogs'),
                onPressed: () {
                  if (dogbookNeedSignIn(context, 'add your dog')) context.push('/book-of-dog/my-dogs');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A dog in a list, with a Follow button.
class DogListTile extends StatelessWidget {
  final String id;
  final Map<String, dynamic> dog;

  const DogListTile({super.key, required this.id, required this.dog});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: DogAvatar(url: (dog['photo_url'] ?? '').toString()),
      title: Text((dog['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text([
        if ((dog['breed'] ?? '').toString().isNotEmpty) dog['breed'],
        '${asInt(dog['follower_count'])} followers',
      ].join(' · ')),
      onTap: () => context.push('/book-of-dog/dog/$id'),
      trailing: FollowButton(dogId: id, ownerUid: (dog['owner_uid'] ?? '').toString()),
    );
  }
}

/// Follow / Following toggle for a dog.
class FollowButton extends StatefulWidget {
  final String dogId;
  final String ownerUid;

  const FollowButton({super.key, required this.dogId, required this.ownerUid});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (!dogbookNeedSignIn(context, 'follow dogs')) return;
    final s = DogbookSession.instance;
    final was = s.following.contains(widget.dogId);
    setState(() => _busy = true);
    s.setFollowing(widget.dogId, !was);
    final r = await DogbookApi.toggleFollow(widget.dogId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      s.setFollowing(widget.dogId, r.data['following'] == true);
    } else {
      s.setFollowing(widget.dogId, was);
      dogbookSnack(context, r.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DogbookSession.instance,
      builder: (context, _) {
        final s = DogbookSession.instance;
        if (s.user?.uid == widget.ownerUid) return const SizedBox.shrink();
        final following = s.following.contains(widget.dogId);
        return following
            ? OutlinedButton(
                onPressed: _busy ? null : _toggle,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: kGold)),
                child: const Text('Following'),
              )
            : FilledButton(
                onPressed: _busy ? null : _toggle,
                style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: Colors.black),
                child: const Text('Follow'),
              );
      },
    );
  }
}
