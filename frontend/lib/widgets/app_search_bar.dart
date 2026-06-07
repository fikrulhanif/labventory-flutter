import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Polished search bar with an animated expand-on-focus transition,
/// integrated clear button, and an optional trailing filter icon.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.hint = 'Search…',
    this.onFilterTap,
    this.hasActiveFilter = false,
  });

  final ValueChanged<String> onChanged;
  final String? initialValue;
  final String hint;

  /// When non-null a filter icon is rendered on the right. The dot
  /// badge appears when [hasActiveFilter] is true.
  final VoidCallback? onFilterTap;
  final bool hasActiveFilter;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focus = FocusNode();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnim = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.easeOutCubic,
    );
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _expandCtrl.forward();
      } else {
        _expandCtrl.reverse();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _expandCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focused = _focus.hasFocus;

    return AnimatedBuilder(
      animation: _expandAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.08 + _expandAnim.value * 0.08,
                ),
                blurRadius: 12 + _expandAnim.value * 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: (v) {
              setState(() {});
              widget.onChanged(v);
            },
            textInputAction: TextInputAction.search,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: focused
                    ? Icon(
                        Icons.search,
                        key: const ValueKey('search'),
                        color: theme.colorScheme.primary,
                      )
                    : Icon(
                        Icons.search,
                        key: const ValueKey('search_idle'),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged('');
                        setState(() {});
                      },
                    ),
                  if (widget.onFilterTap != null)
                    _FilterButton(
                      onTap: widget.onFilterTap!,
                      hasActive: widget.hasActiveFilter,
                    ),
                ],
              ),
              filled: true,
              fillColor: focused
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.8,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap, required this.hasActive});
  final VoidCallback onTap;
  final bool hasActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 20,
              color: hasActive
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (hasActive)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
