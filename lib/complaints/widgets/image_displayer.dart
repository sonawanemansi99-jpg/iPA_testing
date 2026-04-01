import 'package:flutter/material.dart';

  class ImageBox extends StatelessWidget {
  final String path;
  final double height;

  const ImageBox({
    super.key,
    required this.path,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        path,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}