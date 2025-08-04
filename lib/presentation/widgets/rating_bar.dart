import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../core/theme/app_theme.dart';

class RatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final bool readOnly;
  final Function(double)? onRatingUpdate;
  final MainAxisAlignment alignment;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingBar({
    super.key,
    required this.rating,
    this.size = 20.0,
    this.readOnly = true,
    this.onRatingUpdate,
    this.alignment = MainAxisAlignment.start,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, index) => Icon(
            Icons.star,
            color: activeColor ?? AppTheme.starColor,
          ),
          itemCount: 5,
          itemSize: size,
          unratedColor: inactiveColor ?? Colors.grey[300],
          direction: Axis.horizontal,
        ),
        if (!readOnly) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }
}
