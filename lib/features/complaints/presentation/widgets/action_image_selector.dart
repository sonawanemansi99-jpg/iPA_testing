import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/widgets/image_picker_field.dart';

class ComplaintImageSection extends StatefulWidget {
  const ComplaintImageSection({super.key});

  @override
  State<ComplaintImageSection> createState() =>
      _ComplaintImageSectionState();
}

class _ComplaintImageSectionState
    extends State<ComplaintImageSection> {

  List<File> selectedImages = [];

  @override
  Widget build(BuildContext context) {
    return ImagePickerField(
      onImagesSelected: (images) {
        selectedImages = images;
      },
    );
  }
}