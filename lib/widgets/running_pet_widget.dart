import 'package:flutter/material.dart';
import 'sprite_animation.dart';

class RunningPetWidget extends StatefulWidget {
  const RunningPetWidget({super.key});

  @override
  State<RunningPetWidget> createState() => _RunningPetWidgetState();
}

class _RunningPetWidgetState extends State<RunningPetWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  final List<String> _animations = [
    'assets/pets/puppy/corgi puppy trans running happily.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi chasing tail.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi doing a high jump.webp',
    'assets/pets/puppy/finished transparent spritesheet corgi grabbing tale trick.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi head tilting back and forth cute.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi plays dead.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi Running around excited happy.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi Running Fast.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi sneezing.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi walks towards screen then slightly to the left.webp',
    'assets/pets/puppy/finished transparent spritesheet Corgi wants to play and then growls.....webp',
    'assets/pets/puppy/Puppy corgi trans Does big sneeze.webp',
    'assets/pets/puppy/puppy corgi trans does frontflips.webp',
    'assets/pets/puppy/puppy corgi trans does high five trick.webp',
    'assets/pets/puppy/puppy corgi trans eats dinner.webp',
    'assets/pets/puppy/puppy corgi trans flys with cape idle then left up right down for 2 secs each time.webp',
    'assets/pets/puppy/puppy corgi trans goes for a poo 2.webp',
    'assets/pets/puppy/puppy corgi trans going for a wee.webp',
    'assets/pets/puppy/Puppy corgi trans happy jumping around.webp',
    'assets/pets/puppy/puppy corgi trans having a poo.webp',
    'assets/pets/puppy/puppy corgi trans rolls on baby for belly rub.webp',
    'assets/pets/puppy/puppy corgi trans runs around rapidly excited.webp',
    'assets/pets/puppy/puppy corgi trans runs up to the screen from a distance for a boop.webp',
    'assets/pets/puppy/puppy corgi trans sings and howls.webp',
    'assets/pets/puppy/puppy corgi trans sitting down happy patiently waiting for human 2.webp',
    'assets/pets/puppy/puppy corgi trans sitting down happy patiently waiting for human.webp',
    'assets/pets/puppy/puppy corgi trans stands up and shakes body.webp',
    'assets/pets/puppy/puppy corgi trans stands up on 2 legs to beg similar angle to high five.webp',
    'assets/pets/puppy/puppy corgi trans stretching out.webp',
    'assets/pets/puppy/puppy corgi trans walking around.webp',
    'assets/pets/puppy/puppy corgi trans walks around and tale disapears trick.webp',
    'assets/pets/puppy/Puppy corgi trans walks away at an angle and comes back at same angle.webp',
    'assets/pets/puppy/Puppy corgi trans walks away does a full circle and back.webp',
    'assets/pets/puppy/Puppy corgi trans walks casually then sits and looks at screen.webp',
    'assets/pets/puppy/puppy corgi trans wants to play.webp',
    'assets/pets/puppy/puppy corgi trans webp eats fly.webp',
  ];

  @override
  void initState() {
    super.initState();
    // It takes 8 seconds to run across the screen
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // When it finishes crossing the screen, cycle to the next animation
        setState(() {
          _currentIndex = (_currentIndex + 1) % _animations.length;
        });
        // restart the animation
        _controller.forward(from: 0.0);
      }
    });
    
    // Start the first run
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: 200, 
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Center(
                child: child,
              );
            },
            child: SpriteAnimationWidget(
              // Using a key makes flutter fully recreate the widget instead of updating if we want,
              // but we added didUpdateWidget to SpriteAnimationWidget so it handles it smoothly.
              key: ValueKey(_animations[_currentIndex]), 
              imagePath: _animations[_currentIndex],
              columns: 11,
              rows: 11,
              frameCount: 121,
              fps: 12,
              width: 200,
              height: 200,
            ),
          ),
        );
      },
    );
  }
}
