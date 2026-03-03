import 'dart:io';
import 'package:flutter/material.dart';
import 'package:corporator_app/features/complaints/services/image_services.dart';
import '../../../../core/widgets/image_picker_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintImageSection extends StatefulWidget {
  final String complaintId; // Pass the complaint ID to store images
  const ComplaintImageSection({super.key, required this.complaintId});

  @override
  State<ComplaintImageSection> createState() => _ComplaintImageSectionState();
}

class _ComplaintImageSectionState extends State<ComplaintImageSection> {
  List<File> selectedImages = [];
  bool uploading = false;

  Future<void> uploadImages() async {
    if (selectedImages.isEmpty) return;

    setState(() => uploading = true);

    List<String> uploadedUrls = [];

    try {
      for (var file in selectedImages) {
        final url = await uploadImageToCloudinary(file);
        if (url != null) uploadedUrls.add(url);
      }

      if (uploadedUrls.isNotEmpty) {
        // Save URLs to Firestore -> adminImages array
        final query = await FirebaseFirestore.instance
            .collection('complaints')
            .where('complaintId', isEqualTo: widget.complaintId)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final docId = query.docs.first.id;

          await FirebaseFirestore.instance
              .collection('complaints')
              .doc(docId)
              .update({
            'adminImages': FieldValue.arrayUnion(uploadedUrls),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images uploaded successfully')),
      );

      setState(() => selectedImages.clear());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImagePickerField(
          onImagesSelected: (images) {
            setState(() => selectedImages = images);
          },
          // buttonText: 'Select Photos to Upload', // Custom label
        ),
        if (selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: uploading ? null : uploadImages,
            child: Text(uploading ? 'Uploading...' : 'Upload Selected Images'),
          ),
        ],
      ],
    );
  }
}