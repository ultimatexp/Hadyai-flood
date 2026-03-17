import 'package:flutter/material.dart';

class SignalBars extends StatelessWidget {
  final int count;
  final Color color;
  final double height;

  const SignalBars({
    super.key,
    required this.count,
    required this.color,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final barIndex = i + 1;
        final isActive = barIndex <= count;
        return Container(
          width: 4,
          height: height * (barIndex / 3),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
