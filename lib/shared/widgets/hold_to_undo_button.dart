import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

/// 3 saniye basılı tutunca geri alma tetiklenir.
class HoldToUndoButton extends StatefulWidget {
  const HoldToUndoButton({
    super.key,
    required this.label,
    required this.hint,
    required this.onUndo,
    this.holdDuration = const Duration(seconds: 3),
  });

  final String label;
  final String hint;
  final VoidCallback onUndo;
  final Duration holdDuration;

  @override
  State<HoldToUndoButton> createState() => _HoldToUndoButtonState();
}

class _HoldToUndoButtonState extends State<HoldToUndoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _completeTimer;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_holding) return;
    setState(() => _holding = true);
    _controller.forward(from: 0);
    _completeTimer?.cancel();
    _completeTimer = Timer(widget.holdDuration, () {
      if (!mounted) return;
      _reset();
      widget.onUndo();
    });
  }

  void _cancelHold() {
    if (!_holding) return;
    _reset();
  }

  void _reset() {
    _completeTimer?.cancel();
    _controller.stop();
    _controller.value = 0;
    if (mounted) setState(() => _holding = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Listener(
          onPointerDown: (_) => _startHold(),
          onPointerUp: (_) => _cancelHold(),
          onPointerCancel: (_) => _cancelHold(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                height: AppSpacing.tapTargetMin + 8,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FractionallySizedBox(
                        widthFactor: _controller.value,
                        alignment: Alignment.centerLeft,
                        child: ColoredBox(
                          color: AppColors.warning.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        _holding
                            ? 'Bırakmayın… ${((1 - _controller.value) * 3).ceil()}s'
                            : widget.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.onSecondaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.hint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
