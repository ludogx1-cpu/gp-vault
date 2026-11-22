import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api_constants.dart';
import '../src/firebase_service.dart';
import 'package:gp_faucet/src/brand_colors.dart';

/// GPAWS: Golden Paw loyalty points.
///
/// Every so often (at most 5 times an hour, decided by the server) a golden
/// paw peeks out from the edge of the screen. Tapping it collects one GPAW.
/// Only for signed-in players, and only while the app is open in front.
/// GPAWS are loyalty points with no cash value.
class GpawsLayer extends StatefulWidget {
  final Widget child;

  const GpawsLayer({super.key, required this.child});

  @override
  State<GpawsLayer> createState() => _GpawsLayerState();
}

enum _Edge { left, right, bottom }

class _GpawsLayerState extends State<GpawsLayer> with WidgetsBindingObserver, TickerProviderStateMixin {
  static const double _size = 64;

  final _random = Random();
  Timer? _timer;
  StreamSubscription<User?>? _authSub;
  bool _resumed = true;
  bool _busy = false;

  String? _pawId;
  DateTime _expires = DateTime.fromMillisecondsSinceEpoch(0);
  _Edge _edge = _Edge.right;
  double _along = 0.5; // 0..1 position along the edge
  double _tilt = 0;

  late final AnimationController _peek =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _wiggle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  Offset? _burstAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _clearPaw();
      _timer?.cancel();
      // First look a little while after signing in or opening the app.
      if (user != null) _schedule(Duration(seconds: 20 + _random.nextInt(40)));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _timer?.cancel();
    _peek.dispose();
    _wiggle.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed && _pawId == null && FirebaseAuth.instance.currentUser != null) {
      _schedule(Duration(seconds: 10 + _random.nextInt(20)));
    }
  }

  void _schedule(Duration d) {
    _timer?.cancel();
    _timer = Timer(d, _askForPaw);
  }

  void _clearPaw() {
    if (!mounted) return;
    setState(() => _pawId = null);
    _peek.value = 0;
  }

  Future<void> _askForPaw() async {
    if (!mounted || _busy || FirebaseAuth.instance.currentUser == null) return;
    if (_pawId != null && !DateTime.now().isBefore(_expires)) _clearPaw();
    if (!_resumed) {
      _schedule(const Duration(minutes: 1));
      return;
    }
    _busy = true;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/gpaws/spawn'),
        headers: await getAuthHeaders(),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['paw'] is Map) {
        final paw = Map<String, dynamic>.from(data['paw'] as Map);
        final expires = DateTime.fromMillisecondsSinceEpoch((paw['expires_ms'] as num).toInt());
        _showPaw(paw['id'].toString(), expires);
      } else {
        final retry = (data['retry_ms'] as num?)?.toInt() ?? 5 * 60 * 1000;
        // Ask again when the server says, plus a little randomness.
        _schedule(Duration(milliseconds: retry.clamp(30 * 1000, 20 * 60 * 1000) + _random.nextInt(20000)));
      }
    } catch (_) {
      _schedule(const Duration(minutes: 3));
    } finally {
      _busy = false;
    }
  }

  void _showPaw(String id, DateTime expires) {
    if (!mounted) return;
    setState(() {
      _pawId = id;
      _expires = expires;
      _edge = _Edge.values[_random.nextInt(_Edge.values.length)];
      _along = 0.18 + _random.nextDouble() * 0.64;
      _tilt = (_random.nextDouble() - 0.5) * 0.6;
    });
    _peek.forward(from: 0);
    final left = expires.difference(DateTime.now());
    _schedule(left.isNegative ? const Duration(seconds: 5) : left + const Duration(seconds: 2));
  }

  Future<void> _collect(Offset at) async {
    final id = _pawId;
    if (id == null || _busy) return;
    _busy = true;
    setState(() {
      _burstAt = at;
      _pawId = null;
    });
    _burst.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _burstAt = null);
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/gpaws/collect'),
        headers: await getAuthHeaders(),
        body: jsonEncode({'id': id}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final n = (data['gpaws'] as num?)?.toInt() ?? 0;
        messenger?.showSnackBar(SnackBar(
          content: Text('+1 GPAW 🐾  You have $n GPAWS. Thanks for being part of Golden Paw!'),
          backgroundColor: kGold.shade800,
        ));
      } else {
        messenger?.showSnackBar(SnackBar(content: Text((data['error'] ?? 'That paw got away!').toString())));
      }
    } catch (_) {
      messenger?.showSnackBar(const SnackBar(content: Text('Could not reach Golden Paw. That paw got away!')));
    } finally {
      _busy = false;
      _schedule(Duration(seconds: 30 + _random.nextInt(30)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Nothing here blocks taps on the page: an empty Stack is not hit.
        Positioned.fill(
          child: LayoutBuilder(builder: (context, box) {
            final children = <Widget>[];
            if (_pawId != null && DateTime.now().isBefore(_expires)) {
              children.add(_paw(box.biggest));
            }
            if (_burstAt != null && _burst.isAnimating) children.add(_sparkle());
            return Stack(clipBehavior: Clip.hardEdge, children: children);
          }),
        ),
      ],
    );
  }

  /// The paw, about half hidden off the chosen edge.
  Widget _paw(Size area) {
    const s = _size;
    double left, top, angle;
    switch (_edge) {
      case _Edge.left:
        left = -s * 0.45;
        top = (area.height - s) * _along;
        angle = pi / 2 + _tilt;
        break;
      case _Edge.right:
        left = area.width - s * 0.55;
        top = (area.height - s) * _along;
        angle = -pi / 2 + _tilt;
        break;
      case _Edge.bottom:
        left = (area.width - s) * _along;
        top = area.height - s * 0.55;
        angle = _tilt;
        break;
    }
    return Positioned(
      left: left,
      top: top,
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: Listenable.merge([_peek, _wiggle]),
        builder: (context, child) {
          final peek = Curves.easeOutBack.transform(_peek.value.clamp(0.0, 1.0));
          final wiggle = sin(_wiggle.value * pi) * 0.12;
          return Opacity(
            opacity: _peek.value.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: angle + wiggle,
              child: Transform.scale(scale: 0.6 + 0.4 * peek, child: child),
            ),
          );
        },
        child: Semantics(
          button: true,
          label: 'Golden paw. Tap to collect a GPAW.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _collect(Offset(left + d.localPosition.dx, top + d.localPosition.dy)),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kGold.withValues(alpha: 0.55), blurRadius: 18, spreadRadius: 2)],
              ),
              child: Image.asset('assets/gpaw.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  /// Golden sparkles when a paw is collected.
  Widget _sparkle() {
    final at = _burstAt!;
    return AnimatedBuilder(
      animation: _burst,
      builder: (context, _) {
        final t = _burst.value;
        return Stack(children: [
          for (var i = 0; i < 10; i++)
            Positioned(
              left: at.dx + cos(i * pi / 5) * 60 * t - 8,
              top: at.dy + sin(i * pi / 5) * 60 * t - 8,
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Icon(i.isEven ? Icons.star : Icons.pets, size: 16, color: kGold),
              ),
            ),
        ]);
      },
    );
  }
}

/// Shows the player's GPAWS balance, with a short explanation on tap.
class GpawsBadge extends StatelessWidget {
  final int count;

  const GpawsBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'GPAWS are Golden Paw loyalty points. Golden paws peek out around the app '
          '(up to 5 an hour): tap them to collect. They have no cash value.',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: kGold.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kGold.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/gpaw.png', width: 14, height: 14),
            const SizedBox(width: 4),
            Text('$count GPAWS', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
