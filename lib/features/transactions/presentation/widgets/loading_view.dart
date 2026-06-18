import 'package:flutter/material.dart';
import 'package:jeb/core/theme/app_spacing.dart';

/// Skeleton placeholder that gently pulses while data loads — feels faster and
/// more polished than a bare spinner.
class LoadingView extends StatefulWidget {
  const LoadingView({super.key});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 0.95).animate(_controller),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        children: const <Widget>[
          _SkeletonBox(height: 150),
          SizedBox(height: AppSpacing.md),
          _SkeletonBox(height: 190),
          SizedBox(height: AppSpacing.md),
          _SkeletonBox(height: 64),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBox(height: 64),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBox(height: 64),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    );
  }
}
