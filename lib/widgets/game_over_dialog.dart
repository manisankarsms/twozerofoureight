import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Overlay shown when the game ends (won or lost).
class GameOverDialog extends StatelessWidget {
  final bool won;
  final int score;
  final int bestScore;
  final int goal;
  final VoidCallback onNewGame;
  final VoidCallback? onContinue;

  const GameOverDialog({
    super.key,
    required this.won,
    required this.score,
    required this.bestScore,
    required this.goal,
    required this.onNewGame,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? '🎉 You reached $goal!' : 'Game Over',
              style: AppTheme.title.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 10),
            Text(
              'Score: $score',
              style: AppTheme.subtitle.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 4),
            Text(
              'Best: $bestScore',
              style: AppTheme.subtitle,
            ),
            const SizedBox(height: 16),
            if (onContinue != null) ...[
              _ActionButton(
                label: 'Keep Going',
                onTap: onContinue!,
              ),
              const SizedBox(height: 12),
            ],
            _ActionButton(
              label: 'New Game',
              onTap: onNewGame,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label, style: AppTheme.button),
      ),
    );
  }
}
