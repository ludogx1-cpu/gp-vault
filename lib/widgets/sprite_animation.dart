import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpriteAnimationWidget extends StatefulWidget {
  final String imagePath;
  final int columns;
  final int rows;
  final int frameCount;
  final int fps;
  final double width;
  final double height;

  const SpriteAnimationWidget({
    super.key,
    required this.imagePath,
    required this.columns,
    required this.rows,
    required this.frameCount,
    this.fps = 12,
    this.width = 200,
    this.height = 200,
  });

  @override
  State<SpriteAnimationWidget> createState() => _SpriteAnimationWidgetState();
}

class _SpriteAnimationWidgetState extends State<SpriteAnimationWidget>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  late AnimationController _controller;
  late Animation<int> _animation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
    
    // Calculate how long the entire animation should take based on FPS and frame count
    final duration = Duration(milliseconds: (1000 * widget.frameCount / widget.fps).round());
    _controller = AnimationController(vsync: this, duration: duration)..repeat();
    _animation = IntTween(begin: 0, end: widget.frameCount - 1).animate(_controller);
  }

  @override
  void didUpdateWidget(SpriteAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      setState(() {
        _loading = true;
      });
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final ByteData data = await rootBundle.load(widget.imagePath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    
    if (mounted) {
      setState(() {
        _image = frameInfo.image;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _image == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _SpritePainter(
            image: _image!,
            frameIndex: _animation.value,
            columns: widget.columns,
            rows: widget.rows,
          ),
        );
      },
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frameIndex;
  final int columns;
  final int rows;

  _SpritePainter({
    required this.image,
    required this.frameIndex,
    required this.columns,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the width and height of a single frame in the original image
    final double frameWidth = image.width / columns;
    final double frameHeight = image.height / rows;

    // Calculate which column and row this frame index corresponds to
    final int col = frameIndex % columns;
    final int row = frameIndex ~/ columns;

    // The rectangle to extract from the source image
    final Rect srcRect = Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );

    // The rectangle to draw onto the screen
    final Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw with medium filter quality to make it look smooth
    canvas.drawImageRect(image, srcRect, dstRect, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex || oldDelegate.image != image;
  }
}
