import 'dart:math';
import 'package:flutter/material.dart';
import 'sprite_animation.dart';

enum PetState { idle, walking, flying, trick, need }

class RunningPetWidget extends StatefulWidget {
  const RunningPetWidget({super.key});

  @override
  State<RunningPetWidget> createState() => _RunningPetWidgetState();
}

class _RunningPetWidgetState extends State<RunningPetWidget> {
  final List<String> _walkAnimations = [
    'assets/pets/puppy/corgi puppy trans running happily.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi Running Fast.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi Running around excited happy.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi walks towards screen then slightly to the left.webp',
    'assets/pets/puppy/puppy corgi trans runs around rapidly excited.webp',
    'assets/pets/puppy/puppy corgi trans walking around.webp',
    'assets/pets/puppy/Puppy corgi trans walks away does a full circle and back.webp',
    'assets/pets/puppy/Puppy corgi trans walks casually then sits and looks at screen.webp',
  ];

  final List<String> _trickAnimations = [
    'assets/pets/puppy/finished transparent spritesheet Corgi chasing tail.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi doing a high jump.webp',
    'assets/pets/puppy/finished transparent spritesheet corgi grabbing tale trick.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi plays dead.webp',
    'assets/pets/puppy/puppy corgi trans does frontflips.webp',
    'assets/pets/puppy/puppy corgi trans does high five trick.webp',
    'assets/pets/puppy/puppy corgi trans rolls on baby for belly rub.webp',
    'assets/pets/puppy/puppy corgi trans stands up on 2 legs to beg similar angle to high five.webp',
    'assets/pets/puppy/puppy corgi trans walks around and tale disapears trick.webp',
    'assets/pets/puppy/puppy corgi trans wants to play.webp',
  ];

  final List<String> _needAnimations = [
    'assets/pets/puppy/puppy corgi trans eats dinner.webp',
    'assets/pets/puppy/puppy corgi trans goes for a poo 2.webp',
    'assets/pets/puppy/puppy corgi trans going for a wee.webp',
    'assets/pets/puppy/puppy corgi trans having a poo.webp',
    'assets/pets/puppy/puppy corgi trans webp eats fly.webp',
  ];

  final List<String> _idleAnimations = [
    'assets/pets/puppy/finished transparent spritesheet Corgi head tilting back and forth cute.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi sneezing.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi wants to play and then growls.....webp',
    'assets/pets/puppy/Puppy corgi trans Does big sneeze.webp',
    'assets/pets/puppy/Puppy corgi trans happy jumping around.webp',
    'assets/pets/puppy/puppy corgi trans runs up to the screen from a distance for a boop.webp',
    'assets/pets/puppy/puppy corgi trans sings and howls.webp',
    'assets/pets/puppy/puppy corgi trans sitting down happy patiently waiting for human 2.webp',
    'assets/pets/puppy/puppy corgi trans sitting down happy patiently waiting for human.webp',
    'assets/pets/puppy/puppy corgi trans stands up and shakes body.webp',
    'assets/pets/puppy/puppy corgi trans stretching out.webp',
  ];

  final String _flyAnimation = 'assets/pets/puppy/puppy corgi trans flys with cape idle then left up right down for 2 secs each time.webp';

  bool _isActive = true;
  PetState _currentState = PetState.idle;
  String _currentAnimation = '';
  int _startFrame = 0;
  int _endFrame = 120;

  Alignment _currentAlignment = const Alignment(0, 1.0); // Start on ground
  Alignment _targetAlignment = const Alignment(0, 1.0);
  bool _facingLeft = false; // True if we need to mirror flip the sprite
  int _moveDurationSeconds = 1;

  @override
  void initState() {
    super.initState();
    _currentAnimation = _idleAnimations[0];
    _decideNextAction();
  }

  @override
  void dispose() {
    _isActive = false;
    super.dispose();
  }

  Future<void> _decideNextAction() async {
    if (!_isActive) return;
    final rand = Random();

    // Randomly select next state
    final r = rand.nextDouble();
    if (r < 0.4) {
      _currentState = PetState.walking;
    } else if (r < 0.7) {
      _currentState = PetState.flying;
    } else if (r < 0.85) {
      _currentState = PetState.idle;
    } else if (r < 0.95) {
      _currentState = PetState.trick;
    } else {
      _currentState = PetState.need;
    }

    // Default animation config for full loops
    _startFrame = 0;
    _endFrame = 120;
    int actionDuration = 5 + rand.nextInt(4); // 5 to 8 seconds

    if (_currentState == PetState.walking) {
      _currentAnimation = _walkAnimations[rand.nextInt(_walkAnimations.length)];
      
      // Target somewhere on the ground
      double targetX = (rand.nextDouble() * 2) - 1.0;
      _targetAlignment = Alignment(targetX, 1.0);

      // Are we currently flying? Drop down first.
      if (_currentAlignment.y < 1.0) {
         await _flyToGround();
         if (!_isActive) return;
      }

      _facingLeft = targetX < _currentAlignment.x;
      double distance = (targetX - _currentAlignment.x).abs();
      _moveDurationSeconds = (distance * 8).round().clamp(3, 10);
      actionDuration = _moveDurationSeconds;

    } else if (_currentState == PetState.flying) {
      _currentAnimation = _flyAnimation;
      
      // Target anywhere in the sky or ground
      double targetX = (rand.nextDouble() * 2) - 1.0;
      double targetY = (rand.nextDouble() * 2) - 1.0;
      _targetAlignment = Alignment(targetX, targetY);

      double dx = targetX - _currentAlignment.x;
      double dy = targetY - _currentAlignment.y;
      
      // Pick the correct 2-second slice of the flying animation
      if (dx.abs() > dy.abs()) {
        if (dx < 0) {
          _startFrame = 24; _endFrame = 47; // Flying Left
          _facingLeft = false; // Built-in facing left
        } else {
          _startFrame = 72; _endFrame = 95; // Flying Right
          _facingLeft = false;
        }
      } else {
        if (dy < 0) {
          _startFrame = 48; _endFrame = 71; // Flying Up
        } else {
          _startFrame = 96; _endFrame = 119; // Flying Down
        }
        _facingLeft = false;
      }

      double distance = sqrt(dx * dx + dy * dy);
      _moveDurationSeconds = (distance * 6).round().clamp(2, 8);
      actionDuration = _moveDurationSeconds;

    } else {
      // Idle / Trick / Need
      // Force to ground if currently floating
      if (_currentAlignment.y < 1.0) {
        await _flyToGround();
        if (!_isActive) return;
      }

      _targetAlignment = _currentAlignment; // Stay in place
      _moveDurationSeconds = 0; // Instant

      if (_currentState == PetState.idle) {
        _currentAnimation = _idleAnimations[rand.nextInt(_idleAnimations.length)];
      } else if (_currentState == PetState.trick) {
        _currentAnimation = _trickAnimations[rand.nextInt(_trickAnimations.length)];
      } else {
        _currentAnimation = _needAnimations[rand.nextInt(_needAnimations.length)];
      }
    }

    if (mounted) setState(() {});

    // Wait for the action to finish before deciding the next one
    await Future.delayed(Duration(seconds: actionDuration));
    
    _currentAlignment = _targetAlignment;
    _decideNextAction();
  }

  Future<void> _flyToGround() async {
    _currentAnimation = _flyAnimation;
    _startFrame = 96; _endFrame = 119; // Fly down slice
    _facingLeft = false;
    
    _targetAlignment = Alignment(_currentAlignment.x, 1.0);
    double distance = (1.0 - _currentAlignment.y).abs();
    _moveDurationSeconds = (distance * 4).round().clamp(1, 4);
    
    if (mounted) setState(() {});
    await Future.delayed(Duration(seconds: _moveDurationSeconds));
    _currentAlignment = _targetAlignment;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight > 200 ? constraints.maxHeight : 400,
          child: AnimatedAlign(
            alignment: _targetAlignment,
            duration: Duration(seconds: _moveDurationSeconds),
            curve: Curves.linear,
            child: Transform(
              alignment: Alignment.center,
              // Apply a mirror flip if walking left
              transform: _facingLeft ? Matrix4.rotationY(pi) : Matrix4.identity(),
              child: SpriteAnimationWidget(
                key: ValueKey("$_currentAnimation-$_startFrame-$_endFrame"),
                imagePath: _currentAnimation,
                columns: 11,
                rows: 11,
                frameCount: 121,
                fps: 12,
                width: 355,
                height: 200,
                startFrame: _startFrame,
                endFrame: _endFrame,
              ),
            ),
          ),
        );
      },
    );
  }
}
