import 'package:flutter/material.dart';

/// Lightweight pulsing skeleton block. Used as a loading placeholder in
/// inventory list and loan history. Avoids pulling a shimmer package
/// dependency by animating opacity on a [SizedBox] colored with the
/// theme's surfaceContainerHighest.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Tween between two near-identical alphas so the pulse is
        // calm rather than distracting.
        final t = _controller.value;
        final color = Color.lerp(base.withValues(alpha: 0.55), base, t);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Vertical list of skeleton "cards" approximating an inventory or
/// loan list item. Used as a friendlier loading state than a centered
/// CircularProgressIndicator.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 92,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.isGrid = false,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: itemCount,
        itemBuilder: (context, _) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Skeleton(width: 64, height: 64, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 180, height: 14),
                      const SizedBox(height: 8),
                      const Skeleton(width: 120, height: 12),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Skeleton(width: 64, height: 18, radius: 999),
                          SizedBox(width: 8),
                          Skeleton(width: 80, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
