import 'package:flutter/material.dart';

import '../models/tile.dart';
import '../theme/app_theme.dart';

/// Renders a single 2048 tile with value-based styling.
class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;

  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tileColor(tile.value),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '${tile.value}',
          style: AppTheme.tileText(tile.value),
        ),
      ),
    );
  }
}
