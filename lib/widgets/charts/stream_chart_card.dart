import 'package:flutter/material.dart';
import '../../design/stream_theme_extension.dart';
import '../../theme.dart';

class StreamChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  final Key? cardKey;

  const StreamChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height = 220,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final cp = context.$chart;
    return Container(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: StreamSpacing.md),
      padding: const EdgeInsets.all(StreamSpacing.lg),
      decoration: BoxDecoration(
        color: cp.cardBackground,
        borderRadius: BorderRadius.circular(cp.cardRadius),
        border: Border.all(
          color: cp.cardBorderColor,
          width: cp.cardBorderWidth,
        ),
        boxShadow: cp.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: StreamTypography.h3.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: StreamSpacing.md),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}
