import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gp_faucet/src/brand_colors.dart';
import 'dogbook_api.dart';
import 'dogbook_session.dart';
import 'dogbook_widgets.dart';

const _gold = kGold;

ButtonStyle _goldButton() => FilledButton.styleFrom(
      backgroundColor: _gold,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 14),
    );

Widget _rulesNote(BuildContext context) => Text.rich(
      TextSpan(
        text: 'Dogs only, be kind, no links. By posting you agree to the ',
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => context.push('/book-of-dog/rules'),
              child: const Text('Book Of Dog rules',
                  style: TextStyle(fontSize: 12, color: _gold, decoration: TextDecoration.underline)),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => child,
    );

/// Create or edit a dog profile. Returns the dog id when saved.
Future<String?> openDogEditor(BuildContext context, {String? dogId, Map<String, dynamic>? current}) {
  if (!dogbookNeedSignIn(context, 'add your dog')) return Future.value(null);
  return _sheet<String>(context, _DogEditor(dogId: dogId, current: current ?? const {}));
}

class _DogEditor extends StatefulWidget {
  final String? dogId;
  final Map<String, dynamic> current;

  const _DogEditor({this.dogId, required this.current});

  @override
  State<_DogEditor> createState() => _DogEditorState();
}

class _DogEditorState extends State<_DogEditor> {
  late final _name = TextEditingController(text: (widget.current['name'] ?? '').toString());
  late final _breed = TextEditingController(text: (widget.current['breed'] ?? '').toString());
  late final _bio = TextEditingController(text: (widget.current['bio'] ?? '').toString());
  late String _birthday = (widget.current['birthday'] ?? '').toString();
  PickedPhoto? _photo;
  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (mounted) setState(() => _photo = PickedPhoto(bytes, f.name));
    } catch (_) {
      setState(() => _error = 'Could not open that photo.');
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_birthday) ?? DateTime(now.year - 1, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (d != null) {
      setState(() => _birthday =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return setState(() => _error = "Please add your dog's name.");
    setState(() {
      _saving = true;
      _error = '';
    });
    final fields = {
      'name': _name.text.trim(),
      'breed': _breed.text.trim(),
      'bio': _bio.text.trim(),
      'birthday': _birthday,
    };
    final r = widget.dogId == null
        ? await DogbookApi.createDog(fields, photo: _photo)
        : await DogbookApi.updateDog(widget.dogId!, fields, photo: _photo);
    if (!mounted) return;
    if (r.ok) {
      final id = widget.dogId ?? (r.data['id'] ?? '').toString();
      DogbookSession.instance.setActiveDog(id);
      Navigator.pop(context, id);
    } else {
      setState(() {
        _saving = false;
        _error = r.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = (widget.current['photo_url'] ?? '').toString();
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
                Text(widget.dogId == null ? "Add your dog" : 'Edit profile',
                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: _saving ? null : _pick,
                    child: Stack(
                      children: [
                        _photo != null
                            ? CircleAvatar(radius: 48, backgroundImage: MemoryImage(_photo!.bytes))
                            : DogAvatar(url: currentPhoto, radius: 48),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: _gold,
                            child: Icon(Icons.camera_alt, size: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: "Dog's name", border: OutlineInputBorder()),
                ),
                TextField(
                  controller: _breed,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Breed (optional)', border: OutlineInputBorder()),
                ),
                OutlinedButton.icon(
                  onPressed: _pickBirthday,
                  icon: const Icon(Icons.cake_outlined),
                  label: Text(_birthday.isEmpty ? 'Birthday (optional)' : 'Birthday: $_birthday'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bio,
                  maxLength: 200,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'About your dog (optional)', border: OutlineInputBorder()),
                ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error, style: const TextStyle(color: Colors.redAccent)),
                  ),
                _rulesNote(context),
                const SizedBox(height: 12),
                FilledButton(
                  style: _goldButton(),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Write a new post, or re-share one ([reshareOf] = the post id).
/// Returns true when posted.
Future<bool> openComposer(BuildContext context, {String? reshareOf, Map<String, dynamic>? resharePreview}) async {
  if (!dogbookNeedSignIn(context, 'post')) return false;
  final s = DogbookSession.instance;
  if (s.activeDog == null) {
    final made = await openDogEditor(context);
    if (made == null || !context.mounted) return false;
  }
  final posted = await _sheet<bool>(context, _Composer(reshareOf: reshareOf, preview: resharePreview));
  if (posted == true && context.mounted) {
    dogbookSnack(context, reshareOf == null ? 'Posted! 🐾' : 'Shared to your feed! 🐾');
  }
  return posted == true;
}

class _Composer extends StatefulWidget {
  final String? reshareOf;
  final Map<String, dynamic>? preview;

  const _Composer({this.reshareOf, this.preview});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _text = TextEditingController();
  final List<PickedPhoto> _photos = [];
  bool _sending = false;
  String _error = '';

  bool get _isReshare => widget.reshareOf != null;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final room = 4 - _photos.length;
    if (room <= 0) return;
    try {
      final files = room == 1
          ? [?await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, maxHeight: 2000, imageQuality: 85)]
          : await ImagePicker().pickMultiImage(maxWidth: 2000, maxHeight: 2000, imageQuality: 85, limit: room);
      for (final f in files.take(room)) {
        final bytes = await f.readAsBytes();
        _photos.add(PickedPhoto(bytes, f.name));
      }
      if (mounted) setState(() => _error = '');
    } catch (_) {
      setState(() => _error = 'Could not open those photos.');
    }
  }

  Future<void> _send() async {
    final dog = DogbookSession.instance.activeDog;
    if (dog == null) return;
    final text = _text.text.trim();
    if (!_isReshare && text.isEmpty && _photos.isEmpty) {
      return setState(() => _error = 'Write something or add a photo.');
    }
    setState(() {
      _sending = true;
      _error = '';
    });
    final r = _isReshare
        ? await DogbookApi.resharePost(widget.reshareOf!, dog.id, text)
        : await DogbookApi.createPost(dogId: dog.id, text: text, photos: _photos);
    if (!mounted) return;
    if (r.ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _sending = false;
        _error = r.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DogbookSession.instance,
      builder: (context, _) {
        final s = DogbookSession.instance;
        final dogs = s.myDogs.where((d) => !d.hidden).toList();
        final dog = s.activeDog;
        final preview = widget.preview;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_isReshare ? "Share to your dog's feed" : 'New post',
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        DogAvatar(url: dog?.photoUrl ?? ''),
                        const SizedBox(width: 10),
                        const Text('Posting as '),
                        Flexible(
                          child: DropdownButton<String>(
                            value: dog?.id,
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            items: [
                              for (final d in dogs)
                                DropdownMenuItem(
                                  value: d.id,
                                  child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                            ],
                            onChanged: _sending ? null : (id) => id == null ? null : s.setActiveDog(id),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _sending ? null : () => openDogEditor(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add dog'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _text,
                      maxLength: 1000,
                      minLines: 3,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _isReshare ? 'Say something about this (optional)' : "What's your dog up to?",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (preview != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            if (postImageUrls(preview).isNotEmpty)
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: DogbookImage(postImageUrls(preview).first),
                                ),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${preview['dog_name'] ?? ''}: ${preview['caption'] ?? ''}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isReshare) ...[
                      if (_photos.isNotEmpty)
                        SizedBox(
                          height: 92,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (var i = 0; i < _photos.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.memory(_photos[i].bytes, width: 88, height: 88, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        right: 2,
                                        top: 2,
                                        child: InkWell(
                                          onTap: _sending ? null : () => setState(() => _photos.removeAt(i)),
                                          child: const CircleAvatar(
                                            radius: 11,
                                            backgroundColor: Colors.black54,
                                            child: Icon(Icons.close, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: (_sending || _photos.length >= 4) ? null : _addPhotos,
                          icon: const Icon(Icons.add_photo_alternate_outlined, color: _gold),
                          label: Text(_photos.length >= 4 ? '4 photos max' : 'Add photos (${_photos.length}/4)'),
                        ),
                      ),
                    ],
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error, style: const TextStyle(color: Colors.redAccent)),
                      ),
                    _rulesNote(context),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: _goldButton(),
                      onPressed: (_sending || dog == null) ? null : _send,
                      icon: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_isReshare ? Icons.repeat : Icons.send),
                      label: Text(_sending ? 'Posting…' : (_isReshare ? 'Share' : 'Post'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Comments under one post, with one level of replies and paws on comments.
void openComments(BuildContext context, String postId, String dogName) {
  _sheet<void>(
    context,
    SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: CommentsPanel(postId: postId, title: dogName.isEmpty ? 'Comments' : 'Comments for $dogName'),
    ),
  );
}

class CommentsPanel extends StatefulWidget {
  final String postId;
  final String title;

  const CommentsPanel({super.key, required this.postId, required this.title});

  @override
  State<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends State<CommentsPanel> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final Set<String> _liked = {};
  bool _sending = false;
  String? _replyTo;
  String _replyName = '';

  @override
  void initState() {
    super.initState();
    final u = DogbookSession.instance.user;
    if (u != null) {
      FirebaseFirestore.instance
          .collection('dogbook_comment_likes')
          .where('uid', isEqualTo: u.uid)
          .where('post_id', isEqualTo: widget.postId)
          .get()
          .then((snap) {
        if (mounted) setState(() => _liked.addAll(snap.docs.map((d) => (d.data()['comment_id'] ?? '').toString())));
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    if (!dogbookNeedSignIn(context, 'comment')) return;
    setState(() => _sending = true);
    final r = await DogbookApi.addComment(widget.postId, text,
        parentId: _replyTo, dogId: DogbookSession.instance.activeDog?.id);
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.ok) {
      _text.clear();
      setState(() => _replyTo = null);
    } else {
      dogbookSnack(context, r.error);
    }
  }

  Future<void> _like(String id) async {
    if (!dogbookNeedSignIn(context, 'give paws')) return;
    final was = _liked.contains(id);
    setState(() => was ? _liked.remove(id) : _liked.add(id));
    final r = await DogbookApi.toggleCommentLike(id);
    if (!mounted) return;
    setState(() {
      final now = r.ok ? r.data['liked'] == true : was;
      now ? _liked.add(id) : _liked.remove(id);
    });
    if (!r.ok) dogbookSnack(context, r.error);
  }

  Future<void> _delete(String id) async {
    if (!await dogbookConfirm(context, 'Delete this comment?', 'Any replies to it will be removed too.', 'Delete')) {
      return;
    }
    final r = await DogbookApi.deleteComment(id);
    if (mounted && !r.ok) dogbookSnack(context, r.error);
  }

  Widget _comment(QueryDocumentSnapshot<Map<String, dynamic>> d, {required bool isReply, int replies = 0}) {
    final c = d.data();
    final s = DogbookSession.instance;
    final mine = c['uid'] == s.user?.uid;
    final created = tsDate(c['created_at']);
    final who = (c['dog_name'] ?? '').toString().isNotEmpty
        ? '${c['dog_name']} (${c['author_name'] ?? 'Dog lover'})'
        : (c['author_name'] ?? 'Dog lover').toString();
    final liked = _liked.contains(d.id);
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 4, right: 4, top: 6, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(who, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text((c['text'] ?? '').toString(), style: const TextStyle(fontSize: 14)),
                Row(
                  children: [
                    if (created != null)
                      Text(timeAgo(created), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (!isReply)
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () {
                          setState(() {
                            _replyTo = d.id;
                            _replyName = who;
                          });
                          _focus.requestFocus();
                        },
                        child: Text(replies > 0 ? 'Reply · $replies' : 'Reply', style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: liked ? 'Remove paw' : 'Give a paw',
                icon: Icon(liked ? Icons.pets : Icons.pets_outlined, size: 18, color: liked ? _gold : Colors.grey),
                onPressed: () => _like(d.id),
              ),
              Text('${asInt(c['like_count'])}', style: const TextStyle(fontSize: 11)),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            iconSize: 18,
            onSelected: (v) {
              if (v == 'report') dogbookReport(context, 'comment', d.id);
              if (v == 'delete') _delete(d.id);
              if (v == 'block') dogbookBlock(context, (c['uid'] ?? '').toString(), (c['author_name'] ?? '').toString());
            },
            itemBuilder: (_) => [
              if (!mine) const PopupMenuItem(value: 'report', child: Text('Report comment')),
              if (!mine) const PopupMenuItem(value: 'block', child: Text('Hide this person')),
              if (mine || s.isAdmin) const PopupMenuItem(value: 'delete', child: Text('Delete comment')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('dogbook_comments')
        .where('post_id', isEqualTo: widget.postId)
        .where('hidden', isEqualTo: false)
        .orderBy('created_at')
        .limit(300);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return const Center(child: Text('Comments could not load.'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final blocked = DogbookSession.instance.blocked;
                final docs = snap.data!.docs.where((d) => !blocked.contains(d.data()['uid'])).toList();
                final top = docs.where((d) => (d.data()['parent_id'] ?? '').toString().isEmpty).toList();
                final byParent = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
                for (final d in docs) {
                  final p = (d.data()['parent_id'] ?? '').toString();
                  if (p.isNotEmpty) byParent.putIfAbsent(p, () => []).add(d);
                }
                if (top.isEmpty) {
                  return const Center(
                      child: Text('No comments yet. Say something nice!', style: TextStyle(color: Colors.grey)));
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final t in top) ...[
                      _comment(t, isReply: false, replies: byParent[t.id]?.length ?? 0),
                      for (final r in byParent[t.id] ?? const []) _comment(r, isReply: true),
                    ],
                  ],
                );
              },
            ),
          ),
          if (_replyTo != null)
            Container(
              color: _gold.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Replying to $_replyName',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
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
                      focusNode: _focus,
                      maxLength: 300,
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
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send, color: _gold),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
