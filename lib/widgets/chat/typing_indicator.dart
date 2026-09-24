import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/miralo_tokens.dart';

/// Animated 3-dot typing indicator bubble for real-time chat.
class MiraloTypingIndicator extends StatefulWidget {
  final String? userName;
  final bool showBubble;

  const MiraloTypingIndicator({
    super.key,
    this.userName,
    this.showBubble = true,
  });

  @override
  State<MiraloTypingIndicator> createState() => _MiraloTypingIndicatorState();
}

class _MiraloTypingIndicatorState extends State<MiraloTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.2;
        final progress = (_controller.value - delay) % 1.0;
        final bounce = math.sin(progress * math.pi);
        final clampedBounce = bounce > 0 ? bounce : 0.0;
        final translation = -clampedBounce * 5.0;

        return Transform.translate(
          offset: Offset(0, translation),
          child: Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.6 + (clampedBounce * 0.4)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = MiraloColors.accent;
    final bubbleBg = isDark
        ? MiraloColors.darkSurfaceSecondary
        : MiraloColors.lightSurfaceSecondary;
    final border = isDark ? MiraloColors.darkBorder : MiraloColors.lightBorder;

    final dotsRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildDot(0, dotColor),
        _buildDot(1, dotColor),
        _buildDot(2, dotColor),
      ],
    );

    if (!widget.showBubble) {
      return dotsRow;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.userName != null && widget.userName!.isNotEmpty) ...[
                Text(
                  widget.userName!,
                  style: MiraloTypography.caption(color: MiraloColors.accent)
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                ),
                const SizedBox(height: 4),
              ],
              dotsRow,
            ],
          ),
        ),
      ),
    );
  }
}
