import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AdminQRDownloadPage extends StatefulWidget {
  final String adminId;

  const AdminQRDownloadPage({super.key, required this.adminId});

  @override
  State<AdminQRDownloadPage> createState() => _AdminQRDownloadPageState();
}

class _AdminQRDownloadPageState extends State<AdminQRDownloadPage> {
  final GlobalKey qrKey = GlobalKey();

  late String url;

  @override
  void initState() {
    super.initState();

    url = "https://rad-fenglisu-a090b6.netlify.app/?adminId=${widget.adminId}";
  }

  Future<void> downloadQR() async {
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3);

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      Uint8List pngBytes = byteData!.buffer.asUint8List();

      /// SAFE directory for Android / Windows / iOS
      final directory = await getApplicationDocumentsDirectory();

      final file = File("${directory.path}/admin_${widget.adminId}_qr.png");

      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("QR saved at:\n${file.path}")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin QR")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: qrKey,
              child: QrImageView(
                data: url,
                size: 260,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            // ElevatedButton.icon(
            //   onPressed: downloadQR,

            //   icon: const Icon(Icons.download),

            //   label: const Text("Download QR"),
            // ),
          ],
        ),
      ),
    );
  }
}
