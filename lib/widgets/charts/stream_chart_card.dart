import 'package:flutter/material.dart';
import '../../design/stream_theme_extension.dart';
import '../../theme.dart';

class StreamChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;

  const StreamChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Container(
      margin: const EdgeInsets.only(bottom: StreamSpacing.md),
      padding: const EdgeInsets.all(StreamSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: StreamTypography.h3.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: StreamSpacing.md),
          SizedBox(
            height: height,
            child: child,
          ),
        ],
      ),
    );
  }
}
