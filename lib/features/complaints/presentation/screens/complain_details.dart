import 'package:flutter/material.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/domain/model/complaint_model.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/item.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/status_badge.dart';

class ComplainDetails extends StatelessWidget {
  final ComplaintModel complaint;

  const ComplainDetails({super.key, required this.complaint});

  /// Opens full screen image viewer with pinch-to-zoom
  void displayFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 5,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget to show images inline (small previews)
  Widget buildImagePreview(
    String title,
    List<String> images,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        if (images.isEmpty)
          const Text("No images uploaded.")
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => displayFullImage(context, images[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Complaint Details",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          margin: const EdgeInsets.all(10),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Back"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Complaint info
                  item("Complaint ID", complaint.complaintId),
                  item("Name", complaint.name),
                  item("Mobile No.", complaint.mobileNo),
                  item("Email", complaint.email),
                  item(
                      "Description",
                      complaint.description),
                  const SizedBox(height: 10),

                  // Citizen images preview
                  buildImagePreview(
                    "Citizen Uploaded Images",
                    complaint.citizenImages,
                    context,
                  ),

                  // Admin images preview
                  buildImagePreview(
                    "Admin Uploaded Images",
                    complaint.adminImages,
                    context,
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        "Status: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      statusBadge(complaint.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}