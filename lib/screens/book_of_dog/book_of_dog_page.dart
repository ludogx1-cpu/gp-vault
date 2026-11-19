import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../api_constants.dart';
import '../../src/theme_provider.dart';
import '../../widgets/widgets.dart';
import 'package:gp_faucet/src/brand_colors.dart';
import 'dogbook_api.dart';

/// The Book Of Dog: a feed where players share photos of their dogs.
///
/// Visible posts are read straight from Firestore. Sharing, likes, comments,
/// reports and blocking go through the moderated backend (DogbookApi).
class BookOfDogPage extends StatefulWidget {
  const BookOfDogPage({super.key});

  @override
  State<BookOfDogPage> createState() => _BookOfDogPageState();
}

class _BookOfDogPageState extends State<BookOfDogPage> {
  static const int _pageSize = 20;
  int _limit = _pageSize;

  final Set<String> _liked = {};
  final Set<String> _busyLikes = {};
  List<String> _blocked = const [];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<User?>? _authSub;

  User? get _user => FirebaseAuth.instance.currentUser;
  bool get _isAdmin => _user?.uid == ApiConstants.adminUid;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) => _loadMine());
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  /// Loads the signed-in player's likes and block list.
  void _loadMine() {
    _profileSub?.cancel();
    final user = _user;
    if (user == null) {
      if (mounted) {
        setState(() {
          _liked.clear();
          _blocked = const [];
        });
      }
      return;
    }
    _profileSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((snap) {
      final list = snap.data()?['dogbook_blocked'];
      if (mounted) {
        setState(() => _blocked = list is List ? list.whereType<String>().toList() : const []);
      }
    }, onError: (_) {});
    FirebaseFirestore.instance
        .collection('dogbook_likes')
        .where('uid', isEqualTo: user.uid)
        .limit(1000)
        .get()
        .then((snap) {
      if (!mounted) return;
      setState(() {
        _liked
          ..clear()
          ..addAll(snap.docs.map((d) => (d.data()['post_id'] ?? '').toString()));
      });
    }).catchError((_) {});
  }

  void _snack(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  /// Returns true when signed in; otherwise offers the way to sign in.
  bool _needSignIn(String what) {
    if (_user != null) return true;
    _snack('Sign in to $what.',
        action: SnackBarAction(label: 'Sign in', onPressed: () => context.go('/account')));
    return false;
  }

  Future<void> _toggleLike(String postId) async {
    if (!_needSignIn('like posts') || _busyLikes.contains(postId)) return;
    final wasLiked = _liked.contains(postId);
    setState(() {
      _busyLikes.add(postId);
      wasLiked ? _liked.remove(postId) : _liked.add(postId);
    });
    final result = await DogbookApi.toggleLike(postId);
    if (!mounted) return;
    setState(() {
      _busyLikes.remove(postId);
      if (result.ok) {
        result.data['liked'] == true ? _liked.add(postId) : _liked.remove(postId);
      } else {
        wasLiked ? _liked.add(postId) : _liked.remove(postId);
      }
    });
    if (!result.ok) _snack(result.error);
  }

  Future<void> _report(String type, String id) async {
    if (!_needSignIn('report posts')) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(type == 'post' ? 'Report this post' : 'Report this comment'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('What is wrong with it?', style: TextStyle(color: Colors.grey)),
          ),
          for (final r in kDogbookReportReasons)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, r), child: Text(r)),
        ],
      ),
    );
    if (reason == null) return;
    final result = await DogbookApi.report(type, id, reason);
    _snack(result.ok ? 'Thanks for telling us. We will take a look.' : result.error);
  }

  Future<void> _block(String uid, String name) async {
    if (!_needSignIn('hide people')) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hide posts from $name?'),
        content: const Text(
            "You won't see their posts or comments any more. They won't be told. "
            'You can undo this from the menu at the top of The Book Of Dog.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hide them')),
        ],
      ),
    );
    if (ok != true) return;
    final result = await DogbookApi.setBlocked(uid, true);
    _snack(result.ok ? 'Done. You will no longer see posts from $name.' : result.error);
  }

  Future<void> _unblockAll() async {
    final list = List<String>.from(_blocked);
    if (list.isEmpty) {
      _snack("You haven't hidden anyone.");
      return;
    }
    for (final uid in list) {
      final result = await DogbookApi.setBlocked(uid, false);
      if (!result.ok) {
        _snack(result.error);
        return;
      }
    }
    _snack('Everyone you hid is showing again.');
  }

  Future<void> _deletePost(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('The photo, likes and comments will be removed for good.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await DogbookApi.deletePost(id);
    _snack(result.ok ? 'Post deleted.' : result.error);
  }

  Future<void> _openComposer() async {
    if (!_needSignIn('share your dog')) return;
    final shared = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _ShareSheet(),
    );
    if (shared == true) _snack('Your dog is in The Book Of Dog! 🐾');
  }

  void _openComments(Map<String, dynamic> post, String postId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CommentsSheet(
        postId: postId,
        dogName: (post['dog_name'] ?? '').toString(),
        blocked: _blocked,
        isAdmin: _isAdmin,
        onReport: (id) => _report('comment', id),
        needSignIn: _needSignIn,
      ),
    );
  }

  void _openPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url,
                  fit: BoxFit.contain, webHtmlElementStrategy: WebHtmlElementStrategy.prefer),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('dogbook_posts')
        .where('hidden', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .limit(_limit);

    return AppScaffold(
      appBar: const GlobalAppBar(),
      body: ListenableBuilder(
        listenable: themeProvider,
        builder: (context, _) {
          final isDark = themeProvider.isDarkMode;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snap) {
              final docs = (snap.data?.docs ?? const [])
                  .where((d) => !_blocked.contains(d.data()['uid']))
                  .toList();
              final mayHaveMore = (snap.data?.docs.length ?? 0) >= _limit;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _header(isDark),
                      const SizedBox(height: 16),
                      if (snap.hasError)
                        _message('The Book Of Dog could not load. Please try again in a moment.')
                      else if (!snap.hasData)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (docs.isEmpty)
                        _message('No dogs yet. Be the first to share yours! 🐶')
                      else ...[
                        for (final d in docs) _postCard(d.id, d.data(), isDark),
                        if (mayHaveMore)
                          Center(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _limit += _pageSize),
                              child: const Text('Show more dogs'),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      );

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
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 'rules') context.push('/book-of-dog/rules');
                  if (v == 'unblock') _unblockAll();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rules', child: Text('Book Of Dog rules')),
                  if (_user != null && _blocked.isNotEmpty)
                    PopupMenuItem(
                        value: 'unblock', child: Text('Show the ${_blocked.length} people I hid')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Share your dog with other dog lovers. Be kind, dogs only. 🐾',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Share your dog', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _openComposer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(String id, Map<String, dynamic> p, bool isDark) {
    final uid = (p['uid'] ?? '').toString();
    final author = (p['author_name'] ?? 'Dog lover').toString();
    final dogName = (p['dog_name'] ?? '').toString();
    final caption = (p['caption'] ?? '').toString();
    final url = (p['image_url'] ?? '').toString();
    final likes = (p['like_count'] is num) ? (p['like_count'] as num).toInt() : 0;
    final comments = (p['comment_count'] is num) ? (p['comment_count'] as num).toInt() : 0;
    final created = p['created_at'] is Timestamp ? (p['created_at'] as Timestamp).toDate() : null;
    final mine = _user?.uid == uid;
    final liked = _liked.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.only(left: 14, right: 4),
            leading: CircleAvatar(
              backgroundColor: kGold.withValues(alpha: 0.2),
              child: const Icon(Icons.pets, color: kGold, size: 20),
            ),
            title: Text(dogName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('with $author${created != null ? ' · ${timeAgo(created)}' : ''}',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: PopupMenuButton<String>(
              tooltip: 'Options',
              onSelected: (v) {
                if (v == 'report') _report('post', id);
                if (v == 'block') _block(uid, author);
                if (v == 'delete') _deletePost(id);
              },
              itemBuilder: (_) => [
                if (!mine) const PopupMenuItem(value: 'report', child: Text('Report post')),
                if (!mine) PopupMenuItem(value: 'block', child: Text('Hide posts from $author')),
                if (mine || _isAdmin) const PopupMenuItem(value: 'delete', child: Text('Delete post')),
              ],
            ),
          ),
          if (url.isNotEmpty)
            GestureDetector(
              onTap: () => _openPhoto(url),
              onDoubleTap: liked ? null : () => _toggleLike(id),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  loadingBuilder: (c, child, progress) => progress == null
                      ? child
                      : const ColoredBox(
                          color: Colors.black12, child: Center(child: CircularProgressIndicator())),
                  errorBuilder: (c, e, s) => const ColoredBox(
                    color: Colors.black12,
                    child: Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: liked ? 'Unlike' : 'Like',
                  icon: Icon(liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.redAccent : null),
                  onPressed: () => _toggleLike(id),
                ),
                Text('$likes'),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Comments',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => _openComments(p, id),
                ),
                Text('$comments'),
              ],
            ),
          ),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(caption, style: const TextStyle(fontSize: 15, height: 1.35)),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// "5m ago", "3h ago", "2d ago" or a date.
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day}/${t.month}/${t.year}';
}

/// Pick a photo, add the dog's name and a caption, and share it.
class _ShareSheet extends StatefulWidget {
  const _ShareSheet();

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _name = TextEditingController();
  final _caption = TextEditingController();
  XFile? _file;
  Uint8List? _bytes;
  bool _sending = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _file = file;
        _bytes = bytes;
        _error = '';
      });
    } catch (_) {
      setState(() => _error = 'Could not open that photo. Please try another.');
    }
  }

  Future<void> _share() async {
    final name = _name.text.trim();
    if (_bytes == null) return setState(() => _error = 'Please choose a photo of your dog.');
    if (name.isEmpty) return setState(() => _error = "Please add your dog's name.");
    setState(() {
      _sending = true;
      _error = '';
    });
    final result = await DogbookApi.sharePost(
      photo: _bytes!,
      fileName: _file?.name ?? 'dog.jpg',
      dogName: name,
      caption: _caption.text.trim(),
    );
    if (!mounted) return;
    if (result.ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _sending = false;
        _error = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Share your dog',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _sending ? null : _pick,
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kGold.withValues(alpha: 0.6), width: 1.5),
                        color: kGold.withValues(alpha: 0.06),
                      ),
                      child: _bytes == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 48, color: kGold),
                                SizedBox(height: 8),
                                Text('Choose a photo'),
                              ],
                            )
                          : Image.memory(_bytes!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Your dog's name", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _caption,
                  maxLength: 200,
                  maxLines: 3,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Caption (optional)', border: OutlineInputBorder()),
                ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error, style: const TextStyle(color: Colors.redAccent)),
                  ),
                Text.rich(
                  TextSpan(
                    text: 'Dogs only, be kind, no links. By sharing you agree to the ',
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => context.push('/book-of-dog/rules'),
                          child: const Text('Book Of Dog rules',
                              style: TextStyle(
                                  fontSize: 12, color: kGold, decoration: TextDecoration.underline)),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _sending ? null : _share,
                  icon: _sending
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_sending ? 'Sharing…' : 'Share',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Comments under one post.
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final String dogName;
  final List<String> blocked;
  final bool isAdmin;
  final void Function(String commentId) onReport;
  final bool Function(String what) needSignIn;

  const _CommentsSheet({
    required this.postId,
    required this.dogName,
    required this.blocked,
    required this.isAdmin,
    required this.onReport,
    required this.needSignIn,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    if (!widget.needSignIn('comment')) return;
    setState(() => _sending = true);
    final result = await DogbookApi.addComment(widget.postId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.ok) {
      _text.clear();
    } else {
      _snack(result.error);
    }
  }

  Future<void> _delete(String id) async {
    final result = await DogbookApi.deleteComment(id);
    if (mounted && !result.ok) _snack(result.error);
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final query = FirebaseFirestore.instance
        .collection('dogbook_comments')
        .where('post_id', isEqualTo: widget.postId)
        .where('hidden', isEqualTo: false)
        .orderBy('created_at')
        .limit(200);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              widget.dogName.isEmpty ? 'Comments' : 'Comments for ${widget.dogName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: query.snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const Center(child: Text('Comments could not load.'));
                  }
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs
                      .where((d) => !widget.blocked.contains(d.data()['uid']))
                      .toList();
                  if (docs.isEmpty) {
                    return const Center(
                        child: Text('No comments yet. Say something nice!',
                            style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final c = docs[i].data();
                      final id = docs[i].id;
                      final mine = c['uid'] == me;
                      final created = c['created_at'] is Timestamp
                          ? (c['created_at'] as Timestamp).toDate()
                          : null;
                      return ListTile(
                        dense: true,
                        title: Text((c['text'] ?? '').toString(), style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                            '${c['author_name'] ?? 'Dog lover'}${created != null ? ' · ${timeAgo(created)}' : ''}'),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Options',
                          onSelected: (v) {
                            if (v == 'report') widget.onReport(id);
                            if (v == 'delete') _delete(id);
                          },
                          itemBuilder: (_) => [
                            if (!mine) const PopupMenuItem(value: 'report', child: Text('Report comment')),
                            if (mine || widget.isAdmin)
                              const PopupMenuItem(value: 'delete', child: Text('Delete comment')),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        maxLength: 200,
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment…',
                          counterText: '',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Send',
                      icon: _sending
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, color: kGold),
                      onPressed: _sending ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
