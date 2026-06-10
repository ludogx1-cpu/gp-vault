import 'package:flutter/material.dart';
import '../src/theme_provider.dart';

class AnimatedHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;

  const AnimatedHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  @override
  State<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent details) {
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _onExit(PointerEvent details) {
    setState(() => _isHovered = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        final defaultBg = isDark ? themeProvider.darkGreyBoxColor : Colors.white;
        final defaultBorderRadius = widget.borderRadius ?? BorderRadius.circular(15);
        final defaultBorder = widget.border ??
            Border.all(
              color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
              width: 1,
            );

        return MouseRegion(
          onEnter: _onEnter,
          onExit: _onExit,
          cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: widget.onTap,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: widget.margin,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? defaultBg,
                  borderRadius: defaultBorderRadius,
                  border: defaultBorder,
                  boxShadow: _isHovered
                      ? [
                          if (isDark)
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ]
                      : [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                        ],
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
