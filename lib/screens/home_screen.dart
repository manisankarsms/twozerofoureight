import 'package:flutter/material.dart';

import '../data/save_manager.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'gameplay_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SaveManager get _save => SaveManager.instance;
  int _selectedGoal = 2048;

  /// Whether the selected mode matches the resumable session. When it doesn't
  /// (the player picked a different goal), the primary action starts a fresh
  /// game in the selected mode instead of continuing the old one.
  bool get _canContinue =>
      _save.hasActiveSession && _save.save.goal == _selectedGoal;

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onStateChanged);
    _save.addListener(_onStateChanged);
    // Preselect the resumable session's goal so the chips reflect the game the
    // player can continue, rather than defaulting to 2048.
    if (_save.hasActiveSession) {
      _selectedGoal = _save.save.goal;
    }
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onStateChanged);
    _save.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    // Rebuild after the current frame so the ancestor MaterialApp/AnimatedTheme
    // has already applied the new theme. Rebuilding in the same frame as a
    // theme toggle can read a half-applied theme and paint the "2048" title
    // with the wrong color after a dark -> light switch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _startGame({bool startNewGame = false}) async {
    // Start fresh when explicitly requested, when there is no session, or when
    // the player selected a mode different from the resumable session. Only a
    // matching goal resumes the saved board.
    final needsGoal = startNewGame || !_canContinue;
    await Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/gameplay'),
        builder: (_) => GameplayScreen(
          startNewGame: needsGoal,
          goal: needsGoal ? _selectedGoal : null,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleTheme() async {
    final isDark = !AppColors.isDark;
    AppColors.setDark(isDark);
    _save.save.isDarkTheme = isDark;
    themeNotifier.value = isDark;
    await _save.persist();
  }

  @override
  Widget build(BuildContext context) {
    // The selected chip drives the whole screen. A session resumes only when
    // its goal matches the selection (_canContinue).
    final canContinue = _canContinue;
    final activeGoal = _selectedGoal;
    final best = _save.bestScoreFor(activeGoal);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('2048', style: AppTheme.title),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleTheme,
                        tooltip: AppColors.isDark
                            ? 'Use light theme'
                            : 'Use dark theme',
                        icon: Icon(
                          AppColors.isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/settings'),
                        tooltip: 'Settings',
                        icon: Icon(
                          Icons.settings_outlined,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildClassicBadge(),
                  const SizedBox(height: 10),
                  _buildTilePreview(),
                  const SizedBox(height: 16),
                  Text(
                    canContinue
                        ? 'Your game is ready to continue.'
                        : 'Choose a goal and start playing.',
                    textAlign: TextAlign.center,
                    style: AppTheme.subtitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _buildStats(best, canContinue),
                  const SizedBox(height: 28),
                  _buildGoalSelector(),
                  const SizedBox(height: 28),
                  _buildPrimaryAction(canContinue),
                  if (canContinue) ...[
                    const SizedBox(height: 12),
                    _buildNewGameAction(),
                  ],
                  const Spacer(),
                  Text(
                    'Goal: $activeGoal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textDark.withValues(alpha: .62),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.boardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'CLASSIC PUZZLE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildTilePreview() {
    return Center(
      child: Container(
        width: 108,
        height: 108,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.boardBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 7,
          mainAxisSpacing: 7,
          children: const [
            _PreviewTile(value: 2),
            _PreviewTile(value: 4),
            _PreviewTile(value: 8),
            _PreviewTile(value: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(int best, bool canContinue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stat(label: 'BEST', value: '$best'),
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          color: AppColors.textDark.withValues(alpha: .2),
        ),
        _Stat(
          label: canContinue ? 'CURRENT' : 'MODE',
          value: canContinue ? '${_save.save.currentScore}' : '$_selectedGoal',
        ),
      ],
    );
  }

  Widget _buildGoalSelector() {
    const goals = <(int, String)>[
      (2048, 'Classic'),
      (1024, 'Standard'),
      (512, 'Easy'),
      (256, 'Quick'),
    ];
    // Fit all four goals across the available width so none scroll off-screen
    // on narrow devices (256 previously overflowed the right edge).
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (var i = 0; i < goals.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _buildGoalChip(goals[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalChip((int, String) goal) {
    final selected = goal.$1 == _selectedGoal;
    return Semantics(
      button: true,
      selected: selected,
      label: '${goal.$1} ${goal.$2} goal',
      child: Material(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedGoal = goal.$1),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.accent
                    : AppColors.textDark.withValues(alpha: .28),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${goal.$1}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(bool canContinue) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.isDark
              ? const Color(0xFF3C3A32)
              : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          canContinue ? 'Continue Game' : 'Start Game',
          style: AppTheme.button,
        ),
      ),
    );
  }

  Widget _buildNewGameAction() {
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: () => _startGame(startNewGame: true),
        child: Text(
          'New Game',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textDark.withValues(alpha: .62),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tileColor(value),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$value',
        style: AppTheme.tileText(value).copyWith(fontSize: 20),
      ),
    );
  }
}
