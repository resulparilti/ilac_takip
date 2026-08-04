import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

/// Yalnızca yatay kaydırma ile tamamlanır; tek dokunuşla tamamlanmaz.
class SwipeToComplete extends StatefulWidget {
  const SwipeToComplete({
    super.key,
    required this.label,
    required this.onCompleted,
  });

  final String label;
  final VoidCallback onCompleted;

  @override
  State<SwipeToComplete> createState() => _SwipeToCompleteState();
}

class _SwipeToCompleteState extends State<SwipeToComplete> {
  double _dx = 0;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const knobSize = 64.0;
        final maxX = trackWidth - knobSize - 8;
        final progress = maxX <= 0 ? 0.0 : (_dx / maxX).clamp(0.0, 1.0);

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Opacity(
                  opacity: (1 - progress).clamp(0.2, 1.0),
                  child: Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dx,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    if (_done) return;
                    setState(() {
                      _dx = (_dx + d.delta.dx).clamp(0.0, maxX);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_done) return;
                    if (_dx >= maxX * 0.85) {
                      setState(() {
                        _dx = maxX;
                        _done = true;
                      });
                      widget.onCompleted();
                    } else {
                      setState(() => _dx = 0);
                    }
                  },
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: _done ? AppColors.secondary : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _done ? Icons.check : Icons.arrow_forward,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
