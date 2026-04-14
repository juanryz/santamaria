import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animated loading indicator with pulsing Santa Maria logo effect.
class AnimatedLoading extends StatefulWidget {
  final Color? color;
  final double size;
  final String? message;

  const AnimatedLoading({super.key, this.color, this.size = 48, this.message});

  @override
  State<AnimatedLoading> createState() => _AnimatedLoadingState();
}

class _AnimatedLoadingState extends State<AnimatedLoading> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacityAnim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.brandPrimary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Transform.scale(
              scale: _scaleAnim.value,
              child: Opacity(
                opacity: _opacityAnim.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                    color: color.withValues(alpha: 0.08),
                  ),
                  child: Icon(Icons.church, color: color, size: widget.size * 0.45),
                ),
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(widget.message!, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

/// Shimmer placeholder for content loading.
class ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({super.key, this.width = double.infinity, required this.height, this.borderRadius = 12});

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
            end: Alignment(1.0 + 2.0 * _ctrl.value, 0),
            colors: const [
              Color(0xFFEEEEEE),
              Color(0xFFF5F5F5),
              Color(0xFFEEEEEE),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staggered fade-in for list items.
class FadeInListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;

  const FadeInListItem({super.key, required this.index, required this.child, this.delay = const Duration(milliseconds: 50)});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
