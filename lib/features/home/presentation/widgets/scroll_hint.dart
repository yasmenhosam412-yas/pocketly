import 'package:flutter/material.dart';

class HorizontalScrollHint extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const HorizontalScrollHint({
    super.key,
    required this.color,
    this.size = 18,
    this.onTap,
  });

  @override
  State<HorizontalScrollHint> createState() => _HorizontalScrollHintState();
}

class _HorizontalScrollHintState extends State<HorizontalScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Tooltip(
      message: isRtl ? 'عرض المزيد' : 'Scroll to see more',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset((isRtl ? -1 : 1) * _animation.value, 0),
                    child: child,
                  );
                },
                child: Transform.flip(
                  flipX: isRtl,
                  child: Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    size: widget.size,
                    color: widget.color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
