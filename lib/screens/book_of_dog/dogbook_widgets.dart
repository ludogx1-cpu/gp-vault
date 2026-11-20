import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../src/theme_provider.dart';
import 'package:gp_faucet/src/brand_colors.dart';
import 'dogbook_api.dart';
import 'dogbook_session.dart';

/// "5m ago", "3h ago", "2d ago" or a date.
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day}/${t.month}/${t.year}';
}

DateTime? tsDate(dynamic v) => v is Timestamp ? v.toDate() : null;

int asInt(dynamic v) => v is num ? v.toInt() : 0;

void dogbookSnack(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action));
}

/// True when signed in; otherwise offers the way to sign in.
bool dogbookNeedSignIn(BuildContext context, String what) {
  if (DogbookSession.instance.signedIn) return true;
  dogbookSnack(context, 'Sign in to $what.',
      action: SnackBarAction(label: 'Sign in', onPressed: () => context.go('/account')));
  return false;
}

/// Asks for a reason and files a report on a post, comment or dog profile.
Future<void> dogbookReport(BuildContext context, String type, String id) async {
  if (!dogbookNeedSignIn(context, 'report things')) return;
  final what = {'post': 'post', 'comment': 'comment', 'dog': 'dog profile'}[type] ?? 'post';
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text('Report this $what'),
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
  if (context.mounted) {
    dogbookSnack(context, result.ok ? 'Thanks for telling us. We will take a look.' : result.error);
  }
}

/// Hides everything from a player (they are not told).
Future<void> dogbookBlock(BuildContext context, String uid, String name) async {
  if (!dogbookNeedSignIn(context, 'hide people')) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Hide posts from $name?'),
      content: const Text("You won't see their posts or comments any more. They won't be told. "
          'You can undo this from the menu at the top of The Book Of Dog.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hide them')),
      ],
    ),
  );
  if (ok != true) return;
  final result = await DogbookApi.setBlocked(uid, true);
  if (context.mounted) dogbookSnack(context, result.ok ? 'Done. You will no longer see posts from $name.' : result.error);
}

Future<bool> dogbookConfirm(BuildContext context, String title, String body, String action) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Round dog photo, or a gold paw when there is none.
class DogAvatar extends StatelessWidget {
  final String url;
  final double radius;

  const DogAvatar({super.key, required this.url, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: kGold.withValues(alpha: 0.2),
      child: url.isEmpty
          ? Icon(Icons.pets, color: kGold, size: radius)
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (c, e, s) => Icon(Icons.pets, color: kGold, size: radius),
              ),
            ),
    );
  }
}

/// A network photo that loads quietly and copes with errors.
class DogbookImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const DogbookImage(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (c, child, progress) => progress == null
          ? child
          : const ColoredBox(color: Colors.black12, child: Center(child: CircularProgressIndicator())),
      errorBuilder: (c, e, s) => const ColoredBox(
        color: Colors.black12,
        child: Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
      ),
    );
  }
}

void openDogbookPhoto(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(child: DogbookImage(url, fit: BoxFit.contain)),
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

/// Up to 4 photos: one is shown square; more can be swiped, with dots.
class PhotoCarousel extends StatefulWidget {
  final List<String> urls;
  final VoidCallback? onDoubleTap;

  const PhotoCarousel({super.key, required this.urls, this.onDoubleTap});

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => openDogbookPhoto(context, urls[i]),
              onDoubleTap: widget.onDoubleTap,
              child: DogbookImage(urls[i]),
            ),
          ),
          if (urls.length > 1) ...[
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: Text('${_page + 1}/${urls.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < urls.length; i++)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page ? kGold : Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The photo URLs of a post (new posts have a list; older ones one photo).
List<String> postImageUrls(Map<String, dynamic> p) {
  final list = p['images'];
  if (list is List && list.isNotEmpty) {
    return [
      for (final i in list)
        if (i is Map && (i['url'] ?? '').toString().isNotEmpty) i['url'].toString(),
    ];
  }
  final one = (p['image_url'] ?? '').toString();
  return one.isEmpty ? const [] : [one];
}

/// The share menu: re-share to your dog's feed, share to another app, or copy the link.
Future<void> showShareMenu(BuildContext context, String postId, {required VoidCallback onReshare}) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.repeat, color: kGold),
            title: const Text("Share to your dog's feed"),
            onTap: () => Navigator.pop(ctx, 'reshare'),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share, color: kGold),
            title: const Text('Share to another app'),
            subtitle: const Text('WhatsApp, Facebook, messages…'),
            onTap: () => Navigator.pop(ctx, 'system'),
          ),
          ListTile(
            leading: const Icon(Icons.link, color: kGold),
            title: const Text('Copy link'),
            onTap: () => Navigator.pop(ctx, 'copy'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final url = dogbookPostUrl(postId);
  if (choice == 'reshare') {
    onReshare();
    return;
  }
  var copied = choice == 'copy';
  if (choice == 'system') {
    try {
      final r = await SharePlus.instance.share(
        ShareParams(text: 'Look at this dog on The Book Of Dog 🐾 $url', title: 'The Book Of Dog'),
      );
      if (r.status == ShareResultStatus.unavailable) copied = true;
    } catch (_) {
      copied = true;
    }
  }
  if (copied) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) dogbookSnack(context, 'Link copied.');
  }
  if (DogbookSession.instance.signedIn) DogbookApi.countShare(postId);
}

/// One post in the feed.
class PostCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> post;
  final VoidCallback onComments;
  final VoidCallback onReshare;
  final VoidCallback? onDeleted;

  const PostCard({
    super.key,
    required this.id,
    required this.post,
    required this.onComments,
    required this.onReshare,
    this.onDeleted,
  });

  Future<void> _toggleLike(BuildContext context) async {
    if (!dogbookNeedSignIn(context, 'give paws')) return;
    final s = DogbookSession.instance;
    final was = s.likedPosts.contains(id);
    s.setLiked(id, !was);
    final r = await DogbookApi.toggleLike(id);
    if (r.ok) {
      s.setLiked(id, r.data['liked'] == true);
    } else {
      s.setLiked(id, was);
      if (context.mounted) dogbookSnack(context, r.error);
    }
  }

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: (post['caption'] ?? '').toString());
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit post'),
        content: TextField(
          controller: controller,
          maxLength: 1000,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (text == null) return;
    final r = await DogbookApi.editPost(id, text);
    if (context.mounted) dogbookSnack(context, r.ok ? 'Post updated.' : r.error);
  }

  Future<void> _delete(BuildContext context) async {
    if (!await dogbookConfirm(context, 'Delete this post?',
        'The post, its photos, paws and comments will be removed for good.', 'Delete')) {
      return;
    }
    final r = await DogbookApi.deletePost(id);
    if (!context.mounted) return;
    dogbookSnack(context, r.ok ? 'Post deleted.' : r.error);
    if (r.ok) onDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = DogbookSession.instance;
    final isDark = themeProvider.isDarkMode;
    final uid = (post['uid'] ?? '').toString();
    final author = (post['author_name'] ?? 'Dog lover').toString();
    final dogId = (post['dog_id'] ?? '').toString();
    final dogName = (post['dog_name'] ?? '').toString();
    final text = (post['caption'] ?? '').toString();
    final images = postImageUrls(post);
    final reshare = post['reshare_of'] is Map ? Map<String, dynamic>.from(post['reshare_of'] as Map) : null;
    final created = tsDate(post['created_at']);
    final mine = s.user?.uid == uid;
    final liked = s.likedPosts.contains(id);
    void openDog() {
      if (dogId.isNotEmpty) context.push('/book-of-dog/dog/$dogId');
    }

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
            leading: GestureDetector(
              onTap: openDog,
              child: DogAvatar(url: (post['dog_photo_url'] ?? '').toString()),
            ),
            title: GestureDetector(
              onTap: openDog,
              child: Text.rich(
                TextSpan(
                  text: dogName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  children: [
                    if (reshare != null)
                      const TextSpan(
                          text: ' shared a post',
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            subtitle: Text(
              'with $author${created != null ? ' · ${timeAgo(created)}' : ''}${post['edited'] == true ? ' · edited' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Options',
              onSelected: (v) {
                if (v == 'edit') _edit(context);
                if (v == 'delete') _delete(context);
                if (v == 'report') dogbookReport(context, 'post', id);
                if (v == 'block') dogbookBlock(context, uid, author);
                if (v == 'open') context.push('/book-of-dog/post/$id');
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'open', child: Text('Open post')),
                if (mine) const PopupMenuItem(value: 'edit', child: Text('Edit post')),
                if (mine || s.isAdmin) const PopupMenuItem(value: 'delete', child: Text('Delete post')),
                if (!mine) const PopupMenuItem(value: 'report', child: Text('Report post')),
                if (!mine) PopupMenuItem(value: 'block', child: Text('Hide posts from $author')),
              ],
            ),
          ),
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(text, style: const TextStyle(fontSize: 15, height: 1.35)),
            ),
          if (images.isNotEmpty)
            PhotoCarousel(urls: images, onDoubleTap: liked ? null : () => _toggleLike(context)),
          if (reshare != null) _ResharePreview(data: reshare),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: liked ? 'Remove paw' : 'Give a paw',
                  icon: Icon(liked ? Icons.pets : Icons.pets_outlined,
                      color: liked ? kGold : (isDark ? Colors.white70 : Colors.black54)),
                  onPressed: () => _toggleLike(context),
                ),
                Text('${asInt(post['like_count'])}'),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Comments',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: onComments,
                ),
                Text('${asInt(post['comment_count'])}'),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => showShareMenu(context, id, onReshare: onReshare),
                ),
                Text('${asInt(post['share_count'])}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResharePreview extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ResharePreview({required this.data});

  @override
  Widget build(BuildContext context) {
    final img = (data['image_url'] ?? '').toString();
    final text = (data['text'] ?? '').toString();
    final id = (data['id'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: id.isEmpty ? null : () => context.push('/book-of-dog/post/$id'),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGold.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (img.isNotEmpty) SizedBox(height: 220, width: double.infinity, child: DogbookImage(img)),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((data['dog_name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
