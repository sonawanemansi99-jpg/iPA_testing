import 'package:flutter/material.dart';

class CompletedImageSection extends StatelessWidget {
  final List<String>? images;

  const CompletedImageSection({super.key, this.images});

  @override
  Widget build(BuildContext context) {
    if (images == null || images!.isEmpty) {
      return const Text("No evidence photos uploaded.");
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images!.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            images![index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}