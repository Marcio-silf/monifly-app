import 'package:flutter/material.dart';
import 'package:monifly/core/constants/colors.dart';

/// Paper airplane loading indicator (animated circle progress + plane icon)
class MoniflyLoadingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const MoniflyLoadingIndicator({super.key, this.color, this.size = 48});

  @override
  State<MoniflyLoadingIndicator> createState() =>
      _MoniflyLoadingIndicatorState();
}

class _MoniflyLoadingIndicatorState extends State<MoniflyLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Spinning circle
          RotationTransition(
            turns: _controller,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.color ?? AppColors.primary,
              ),
            ),
          ),
          // Plane emoji
          ClipOval(
            child: Image.asset(
              'assets/images/logo/logo_monifly.png',
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class MoniflyLoader extends StatelessWidget {
  final String? message;
  const MoniflyLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MoniflyLoadingIndicator(size: 64),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}


