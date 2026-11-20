import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../api_constants.dart';

/// One of the signed-in player's dog profiles.
class MyDog {
  final String id;
  final String name;
  final String breed;
  final String photoUrl;
  final bool hidden;

  const MyDog({
    required this.id,
    required this.name,
    required this.breed,
    required this.photoUrl,
    required this.hidden,
  });

  factory MyDog.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const {};
    return MyDog(
      id: d.id,
      name: (m['name'] ?? '').toString(),
      breed: (m['breed'] ?? '').toString(),
      photoUrl: (m['photo_url'] ?? '').toString(),
      hidden: m['hidden'] == true,
    );
  }
}

/// What the signed-in player has done in The Book Of Dog: their dogs, the
/// posts they like, the dogs they follow, who they've hidden and how many
/// notifications are unread. Shared by every Book Of Dog screen.
class DogbookSession extends ChangeNotifier {
  DogbookSession._() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) => _load());
  }

  static final DogbookSession instance = DogbookSession._();

  final Set<String> likedPosts = {};
  final Set<String> following = {};
  List<MyDog> myDogs = const [];
  List<String> blocked = const [];
  int unread = 0;

  /// The dog new posts and comments come from (the first one by default).
  String? activeDogId;

  StreamSubscription<User?>? _authSub;
  final List<StreamSubscription> _subs = [];

  User? get user => FirebaseAuth.instance.currentUser;
  bool get signedIn => user != null;
  bool get isAdmin => user?.uid == ApiConstants.adminUid;

  MyDog? get activeDog {
    final visible = myDogs.where((d) => !d.hidden).toList();
    if (visible.isEmpty) return null;
    return visible.firstWhere((d) => d.id == activeDogId, orElse: () => visible.first);
  }

  void setActiveDog(String id) {
    activeDogId = id;
    notifyListeners();
  }

  void _load() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    likedPosts.clear();
    following.clear();
    myDogs = const [];
    blocked = const [];
    unread = 0;
    final u = user;
    if (u == null) {
      notifyListeners();
      return;
    }
    final fs = FirebaseFirestore.instance;
    _subs.add(fs.collection('users').doc(u.uid).snapshots().listen((snap) {
      final list = snap.data()?['dogbook_blocked'];
      blocked = list is List ? list.whereType<String>().toList() : const [];
      notifyListeners();
    }, onError: (_) {}));
    _subs.add(fs.collection('dogbook_dogs').where('owner_uid', isEqualTo: u.uid).snapshots().listen((snap) {
      myDogs = snap.docs.map(MyDog.fromDoc).toList()..sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }, onError: (_) {}));
    _subs.add(fs.collection('dogbook_follows').where('uid', isEqualTo: u.uid).snapshots().listen((snap) {
      following
        ..clear()
        ..addAll(snap.docs.map((d) => (d.data()['dog_id'] ?? '').toString()));
      notifyListeners();
    }, onError: (_) {}));
    _subs.add(fs
        .collection('dogbook_notifications')
        .where('to_uid', isEqualTo: u.uid)
        .where('read', isEqualTo: false)
        .limit(99)
        .snapshots()
        .listen((snap) {
      unread = snap.size;
      notifyListeners();
    }, onError: (_) {}));
    fs.collection('dogbook_likes').where('uid', isEqualTo: u.uid).limit(2000).get().then((snap) {
      likedPosts
        ..clear()
        ..addAll(snap.docs.map((d) => (d.data()['post_id'] ?? '').toString()));
      notifyListeners();
    }).catchError((_) {});
  }

  void setLiked(String postId, bool liked) {
    liked ? likedPosts.add(postId) : likedPosts.remove(postId);
    notifyListeners();
  }

  void setFollowing(String dogId, bool value) {
    value ? following.add(dogId) : following.remove(dogId);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
