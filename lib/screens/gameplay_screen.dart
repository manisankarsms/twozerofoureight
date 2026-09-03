import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/save_manager.dart';
import '../game/game_controller.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/tile_widget.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key, this.startNewGame = false, this.goal});

  final bool startNewGame;
  final int? goal;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with WidgetsBindingObserver {
  late final GameController _controller;
  final SaveManager _save = SaveManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final goal = !widget.startNewGame && _save.hasActiveSession
        ? _save.save.goal
        : widget.goal ?? 2048;
    _controller = GameController(goal: goal);
    _controller.addListener(_onGameUpdate);
    _initGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onGameUpdate);
    unawaited(_save.flush());
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_save.flush());
    }
  }

  void _initGame() {
    if (!widget.startNewGame && _save.hasActiveSession) {
      final savedStatus = GameStatus.values.firstWhere(
        (status) => status.name == _save.save.gameStatus,
        orElse: () => GameStatus.playing,
      );
      _controller.restoreFromBoard(
        _save.save.boardState!,
        _save.save.currentScore,
        savedStatus: savedStatus,
        savedHasWon: _save.save.hasWon,
      );
    } else {
      _controller.newGame();
    }
  }

  bool _lossHandled = false;
  bool _isExiting = false;

  void _onGameUpdate() {
    if (mounted) setState(() {});

    final isNewLoss = _controller.status == GameStatus.lost && !_lossHandled;
    if (_controller.status != GameStatus.lost) _lossHandled = false;
    if (isNewLoss) _lossHandled = true;

    unawaited(_persistGameState(showInterstitial: isNewLoss));
  }

  Future<void> _persistGameState({required bool showInterstitial}) async {
    await _save.recordGameState(
      board: _controller.flatBoard,
      score: _controller.score,
      goal: _controller.goal,
      status: _controller.status.name,
      hasWon: _controller.hasWon,
    );

    if (!showInterstitial || !await _save.recordCompletedGame()) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await AdService.instance.showInterstitialIfAvailable();
  }

  void _onNewGame() {
    _controller.newGame();
  }

  void _onContinue() {
    _controller.continueGame();
  }

  /// Leaves the game from the overlay. State is already persisted, so the home
  /// screen reflects the latest board (or a cleared session after a loss).
  void _exitToHome() {
    if (!mounted) return;
    setState(() => _isExiting = true);
    Navigator.of(context).pop();
  }

  void _handleSwipe(MoveDirection direction) {
    final moved = _controller.move(direction);
    if (moved) HapticFeedback.lightImpact();
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity == null) return;
    if (velocity < -100) {
      _handleSwipe(MoveDirection.up);
    } else if (velocity > 100) {
      _handleSwipe(MoveDirection.down);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity == null) return;
    if (velocity < -100) {
      _handleSwipe(MoveDirection.left);
    } else if (velocity > 100) {
      _handleSwipe(MoveDirection.right);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isExiting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  // Swipes anywhere below the header move the board, including
                  // the empty space under it, so short flicks off the grid
                  // still count.
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragEnd: _onVerticalDragEnd,
                      onHorizontalDragEnd: _onHorizontalDragEnd,
                      child: Column(
                        children: [
                          const Spacer(),
                          _buildBoard(context),
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_controller.status != GameStatus.playing)
              _GameEndOverlay(
                child: GameOverDialog(
                  won: _controller.status == GameStatus.won,
                  score: _controller.score,
                  bestScore: _save.bestScoreFor(_controller.goal),
                  goal: _controller.goal,
                  onNewGame: _onNewGame,
                  onExit: _exitToHome,
                  onContinue: _controller.status == GameStatus.won
                      ? _onContinue
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('2048', style: AppTheme.title),
          const Spacer(),
          _ScoreBox(label: 'SCORE', value: _controller.score),
          const SizedBox(width: 8),
          _ScoreBox(label: 'BEST', value: _save.bestScoreFor(_controller.goal)),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _confirmExit,
            tooltip: 'Exit game',
            color: AppColors.textDark,
            icon: const Icon(Icons.exit_to_app_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit game?'),
        content: const Text(
          'Your current game is saved and can be continued later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) {
      setState(() => _isExiting = true);
      Navigator.of(context).pop();
    }
  }

  Widget _buildBoard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth - 32;
    const spacing = 8.0;
    final tileSize =
        (boardSize - spacing * (GameController.gridSize + 1)) /
        GameController.gridSize;

    return Stack(
      children: [
        Container(
          width: boardSize,
          height: boardSize,
          padding: const EdgeInsets.all(spacing),
          decoration: BoxDecoration(
            color: AppColors.boardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: GameController.gridSize,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
            ),
            itemCount: GameController.gridSize * GameController.gridSize,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.emptyCell,
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: _controller.tiles.map((tile) {
              final left = spacing + tile.col * (tileSize + spacing);
              final top = spacing + tile.row * (tileSize + spacing);
              return AnimatedPositioned(
                key: ValueKey(tile.id),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                left: left,
                top: top,
                child: TileWidget(tile: tile, size: tileSize),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.scoreBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEEE4DA),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen backdrop that blurs and dims the game, then eases the
/// end-of-game card in with a synchronized fade + scale.
class _GameEndOverlay extends StatefulWidget {
  const _GameEndOverlay({required this.child});

  final Widget child;

  @override
  State<_GameEndOverlay> createState() => _GameEndOverlayState();
}

class _GameEndOverlayState extends State<_GameEndOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.88,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: AnimatedBuilder(
          animation: _fade,
          builder: (context, child) {
            final t = _fade.value;
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55 * t),
                child: child,
              ),
            );
          },
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ScaleTransition(scale: _scale, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
