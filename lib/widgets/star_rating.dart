import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final double initialRating;
  final double size;
  final bool readOnly;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    this.initialRating = 0,
    this.size = 32,
    this.readOnly = false,
    this.onRatingChanged,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1.0;
        final isFilled = _rating >= starValue;
        final isHalf = _rating >= starValue - 0.5 && _rating < starValue;

        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() => _rating = starValue);
                  widget.onRatingChanged?.call(starValue);
                },
          child: Icon(
            isFilled
                ? Icons.star_rounded
                : isHalf
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            color: isFilled || isHalf
                ? const Color(0xFFFFB300)
                : const Color(0xFFE0E0E0),
            size: widget.size,
          ),
        );
      }),
    );
  }
}

// ── Read-only compact star display ────────────────────────────────────────────

class StarDisplay extends StatelessWidget {
  final double rating;
  final int count;
  final double size;

  const StarDisplay({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded,
              color: const Color(0xFFE0E0E0), size: size),
          const SizedBox(width: 2),
          Text('No ratings yet',
              style: TextStyle(
                  fontSize: size - 2, color: const Color(0xFF9E9E9E))),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: size),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size - 1,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 2),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size - 2,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ],
    );
  }
}
