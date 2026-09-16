import 'package:flutter/material.dart';

/// Centers [child] and caps its width. Mobile screens are narrow enough
/// that this never kicks in, but on a desktop window (which can be
/// 1000px+ wide) content designed for a phone-width layout would
/// otherwise stretch edge-to-edge and look oversized. Wrap a screen's
/// top-level scrollable in this to keep it a comfortable, phone-like
/// width no matter how wide the window is.
class MaxWidthBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidthBox({super.key, required this.child, this.maxWidth = 520});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
