import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card shown when the game ends (won or lost). Rendered above a full-screen
/// backdrop by the gameplay screen.
class GameOverDialog extends StatelessWidget {
  final bool won;
  final int score;
  final int bestScore;
  final int goal;
  final VoidCallback onNewGame;
  final VoidCallback? onContinue;
  final VoidCallback onExit;

  const GameOverDialog({
    super.key,
    required this.won,
    required this.score,
    required this.bestScore,
    required this.goal,
    required this.onNewGame,
    required this.onExit,
    this.onContinue,
  });

  bool get _isNewBest => score >= bestScore && score > 0;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.isDark
              ? const Color(0xFF2D2D44)
              : const Color(0xFFFAF8EF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Badge(won: won),
            const SizedBox(height: 18),
            Text(
              won ? 'You reached $goal!' : 'Game Over',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              won
                  ? 'Keep going for an even higher score.'
                  : 'No moves left. Give it another go.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark.withValues(alpha: .7),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    label: 'SCORE',
                    value: '$score',
                    highlight: _isNewBest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatPill(label: 'BEST', value: '$bestScore'),
                ),
              ],
            ),
            if (_isNewBest) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'New best score!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (onContinue != null) ...[
              _ActionButton(
                label: 'Keep Going',
                icon: Icons.play_arrow_rounded,
                onTap: onContinue!,
              ),
              const SizedBox(height: 10),
            ],
            _ActionButton(
              label: 'New Game',
              icon: Icons.refresh_rounded,
              onTap: onNewGame,
              // When the win overlay offers Keep Going, New Game is secondary.
              filled: onContinue == null,
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onExit,
              icon: Icon(
                Icons.home_rounded,
                size: 18,
                color: AppColors.textDark.withValues(alpha: .8),
              ),
              label: Text(
                'Exit to Home',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark.withValues(alpha: .8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular icon badge at the top of the card.
class _Badge extends StatelessWidget {
  const _Badge({required this.won});

  final bool won;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (won ? AppColors.accent : AppColors.textDark).withValues(
          alpha: .14,
        ),
      ),
      child: Icon(
        won ? Icons.celebration_rounded : Icons.sentiment_dissatisfied_rounded,
        size: 34,
        color: won ? AppColors.accent : AppColors.textDark,
      ),
    );
  }
}

/// A rounded pill showing one score value with its label.
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = highlight;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent
            ? AppColors.accent.withValues(alpha: .16)
            : AppColors.textDark.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
        border: accent
            ? Border.all(color: AppColors.accent.withValues(alpha: .5))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.textDark.withValues(alpha: .6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent ? AppColors.accent : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    // No color here — the label inherits the button's foregroundColor (white
    // when filled, accent when outlined).
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ],
    );

    if (!filled) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: AppColors.accent.withValues(alpha: .6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
    );
  }
}
