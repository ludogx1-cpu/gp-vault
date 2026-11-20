import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../src/theme_provider.dart';
import '../../widgets/widgets.dart';
import 'package:gp_faucet/src/brand_colors.dart';
import 'book_of_dog_page.dart' show FollowButton;
import 'dogbook_api.dart';
import 'dogbook_session.dart';
import 'dogbook_sheets.dart';
import 'dogbook_widgets.dart';

Widget _page(BuildContext context, Widget child) => AppScaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: ListenableBuilder(
        listenable: Listenable.merge([themeProvider, DogbookSession.instance]),
        builder: (context, _) => Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: child),
        ),
      ),
    );

Widget _centered(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      ),
    );

String _ageOf(String birthday) {
  final b = DateTime.tryParse(birthday);
  if (b == null) return '';
  final now = DateTime.now();
  var months = (now.year - b.year) * 12 + now.month - b.month - (now.day < b.day ? 1 : 0);
  if (months < 0) months = 0;
  if (months < 12) return months <= 1 ? 'Puppy' : '$months months old';
  final years = months ~/ 12;
  return years == 1 ? '1 year old' : '$years years old';
}

/// A dog's profile: photo, details, followers and their posts.
class DogProfilePage extends StatelessWidget {
  final String dogId;

  const DogProfilePage({super.key, required this.dogId});

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    return _page(
      context,
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: fs.collection('dogbook_dogs').doc(dogId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return _centered('This dog profile is not available.');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (!snap.data!.exists) return _centered('This dog profile has been removed.');
          final dog = snap.data!.data()!;
          final s = DogbookSession.instance;
          final mine = dog['owner_uid'] == s.user?.uid;
          final posts = fs
              .collection('dogbook_posts')
              .where('dog_id', isEqualTo: dogId)
              .where('hidden', isEqualTo: false)
              .orderBy('created_at', descending: true)
              .limit(40);
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: posts.snapshots(),
            builder: (context, ps) {
              final docs = (ps.data?.docs ?? const []).where((d) => !s.blocked.contains(d.data()['uid'])).toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _profileHeader(context, dog, mine),
                  const SizedBox(height: 16),
                  if (ps.hasError) _centered('Posts could not load.'),
                  if (!ps.hasData && !ps.hasError) const Center(child: CircularProgressIndicator()),
                  if (ps.hasData && docs.isEmpty)
                    _centered(mine ? 'No posts yet. Write your first one!' : 'No posts yet.'),
                  for (final d in docs)
                    PostCard(
                      id: d.id,
                      post: d.data(),
                      onComments: () => openComments(context, d.id, (d.data()['dog_name'] ?? '').toString()),
                      onReshare: () => openComposer(context, reshareOf: d.id, resharePreview: d.data()),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _profileHeader(BuildContext context, Map<String, dynamic> dog, bool mine) {
    final isDark = themeProvider.isDarkMode;
    final breed = (dog['breed'] ?? '').toString();
    final age = _ageOf((dog['birthday'] ?? '').toString());
    final bio = (dog['bio'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGold.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: (dog['photo_url'] ?? '').toString().isEmpty
                ? null
                : () => openDogbookPhoto(context, dog['photo_url'].toString()),
            child: DogAvatar(url: (dog['photo_url'] ?? '').toString(), radius: 52),
          ),
          const SizedBox(height: 12),
          Text((dog['name'] ?? '').toString(),
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w700)),
          if (breed.isNotEmpty || age.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text([breed, age].where((e) => e.isNotEmpty).join(' · '),
                  style: const TextStyle(color: Colors.grey)),
            ),
          if (bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(bio, textAlign: TextAlign.center),
            ),
          const SizedBox(height: 12),
          Text('${asInt(dog['follower_count'])} followers · ${asInt(dog['post_count'])} posts',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (dog['hidden'] == true)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('This profile is hidden while it is reviewed.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (!mine) FollowButton(dogId: dogId, ownerUid: (dog['owner_uid'] ?? '').toString()),
              if (mine)
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: Colors.black),
                  onPressed: () => openDogEditor(context, dogId: dogId, current: dog),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit profile'),
                ),
              if (mine)
                OutlinedButton.icon(
                  onPressed: () {
                    DogbookSession.instance.setActiveDog(dogId);
                    openComposer(context);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Write a post'),
                ),
              if (!mine)
                TextButton.icon(
                  onPressed: () => dogbookReport(context, 'dog', dogId),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Report'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One post on its own page, with its comments. Shared links open here.
class DogbookPostPage extends StatelessWidget {
  final String postId;

  const DogbookPostPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return _page(
      context,
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('dogbook_posts').doc(postId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return _centered('This post is not available.');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (!snap.data!.exists) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _centered('This post has been removed.'),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: Colors.black),
                  onPressed: () => context.go('/book-of-dog'),
                  child: const Text('Go to The Book Of Dog'),
                ),
              ],
            );
          }
          final post = snap.data!.data()!;
          final dogName = (post['dog_name'] ?? '').toString();
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PostCard(
                      id: postId,
                      post: post,
                      onComments: () => openComments(context, postId, dogName),
                      onReshare: () => openComposer(context, reshareOf: postId, resharePreview: post),
                      onDeleted: () => context.go('/book-of-dog'),
                    ),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/book-of-dog'),
                        icon: const Icon(Icons.pets, color: kGold),
                        label: const Text('See more dogs in The Book Of Dog'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                flex: 2,
                child: CommentsPanel(postId: postId, title: 'Comments'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Paws, comments, replies, re-shares and new followers.
class DogbookNotificationsPage extends StatefulWidget {
  const DogbookNotificationsPage({super.key});

  @override
  State<DogbookNotificationsPage> createState() => _DogbookNotificationsPageState();
}

class _DogbookNotificationsPageState extends State<DogbookNotificationsPage> {
  @override
  void initState() {
    super.initState();
    if (DogbookSession.instance.unread > 0) DogbookApi.markNotificationsRead();
  }

  static (IconData, String) _describe(Map<String, dynamic> n) {
    final who = (n['from_name'] ?? 'Someone').toString();
    switch (n['type']) {
      case 'like':
        return (Icons.pets, '$who gave your post a paw');
      case 'comment_like':
        return (Icons.pets, '$who gave your comment a paw');
      case 'comment':
        return (Icons.chat_bubble_outline, '$who commented on your post');
      case 'reply':
        return (Icons.reply, '$who replied to your comment');
      case 'reshare':
        return (Icons.repeat, '$who shared your post');
      case 'follow':
        return (Icons.favorite_outline, '$who started following ${n['text'] ?? 'your dog'}');
      default:
        return (Icons.notifications_outlined, '$who did something');
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = DogbookSession.instance.user;
    if (u == null) return _page(context, _centered('Sign in to see your notifications.'));
    final query = FirebaseFirestore.instance
        .collection('dogbook_notifications')
        .where('to_uid', isEqualTo: u.uid)
        .orderBy('created_at', descending: true)
        .limit(60);
    return _page(
      context,
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return _centered('Notifications could not load.');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Notifications',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (docs.isEmpty) _centered('Nothing yet. Paws, comments and new followers will show up here.'),
              for (final d in docs)
                Builder(builder: (context) {
                  final n = d.data();
                  final (icon, title) = _describe(n);
                  final created = tsDate(n['created_at']);
                  final text = (n['text'] ?? '').toString();
                  final postId = (n['post_id'] ?? '').toString();
                  final dogId = (n['dog_id'] ?? '').toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: kGold.withValues(alpha: n['read'] == true ? 0.12 : 0.35),
                      child: Icon(icon, color: kGold),
                    ),
                    title: Text(title,
                        style: TextStyle(fontWeight: n['read'] == true ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Text([
                      if (text.isNotEmpty && n['type'] != 'follow') '"$text"',
                      if (created != null) timeAgo(created),
                    ].join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      if (postId.isNotEmpty) {
                        context.push('/book-of-dog/post/$postId');
                      } else if (dogId.isNotEmpty) {
                        context.push('/book-of-dog/dog/$dogId');
                      }
                    },
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

/// The signed-in player's dog profiles.
class MyDogsPage extends StatelessWidget {
  const MyDogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _page(
      context,
      Builder(builder: (context) {
        final s = DogbookSession.instance;
        if (!s.signedIn) return _centered('Sign in to add your dogs.');
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('My dogs', style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Each dog gets its own profile that other dog lovers can follow.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            for (final d in s.myDogs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: DogAvatar(url: d.photoUrl),
                title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(d.hidden ? 'Hidden while it is reviewed' : (d.breed.isEmpty ? 'Dog' : d.breed)),
                onTap: () => context.push('/book-of-dog/dog/${d.id}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      if (!await dogbookConfirm(context, 'Delete ${d.name}?',
                          "This removes ${d.name}'s profile and all of their posts for good.", 'Delete')) {
                        return;
                      }
                      final r = await DogbookApi.deleteDog(d.id);
                      if (context.mounted) dogbookSnack(context, r.ok ? 'Profile deleted.' : r.error);
                    }
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete profile'))],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => openDogEditor(context),
              icon: const Icon(Icons.add),
              label: Text(s.myDogs.isEmpty ? 'Add your dog' : 'Add another dog',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }
}
