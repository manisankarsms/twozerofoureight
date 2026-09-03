import 'package:flutter/material.dart';

import '../models/tile.dart';
import '../theme/app_theme.dart';

/// Renders a single 2048 tile with value-based styling.
///
/// Owns two entrance animations driven by the model:
///  - [Tile.isNew] tiles scale in from zero (spawn pop).
///  - [Tile.merged] tiles do a brief overshoot pop that settles back to 1.0.
/// Colour changes on merge are eased via [AnimatedContainer].
class TileWidget extends StatefulWidget {
  final Tile tile;
  final double size;

  const TileWidget({super.key, required this.tile, required this.size});

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _configureAnimation(spawn: widget.tile.isNew);
    // Animate on first build for spawns; merges are handled in didUpdateWidget.
    if (widget.tile.isNew || widget.tile.merged) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A value change means this tile just absorbed another — replay the pop.
    if (widget.tile.value != oldWidget.tile.value) {
      _configureAnimation(spawn: false);
      _controller.forward(from: 0);
    }
  }

  /// A spawn grows 0 -> 1; a merge overshoots to 1.18 then settles to 1.0.
  void _configureAnimation({required bool spawn}) {
    if (spawn) {
      _scale = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );
    } else {
      _scale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1,
            end: 1.18,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.18,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.tileColor(widget.tile.value),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: AppTheme.tileText(widget.tile.value),
          child: Text('${widget.tile.value}'),
        ),
      ),
    );
  }
}
