import 'package:flutter/material.dart';

class ReviewStars extends StatelessWidget {
  final double rating;
  final int? count;
  final bool interactive;
  final Function(int)? onRatingChanged;

  const ReviewStars({
    super.key,
    required this.rating,
    this.count,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final position = index + 1;
          IconData iconData;
          if (rating >= position) {
            iconData = Icons.star;
          } else if (rating >= position - 0.5) {
            iconData = Icons.star_half;
          } else {
            iconData = Icons.star_border;
          }

          final star = Icon(iconData, color: Colors.amber, size: 18);

          if (interactive) {
            return InkWell(
              onTap: () => onRatingChanged?.call(position),
              borderRadius: BorderRadius.circular(4),
              child: star,
            );
          }
          return star;
        }),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
