import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CorporatorQRDownloadPage extends StatefulWidget {
  const CorporatorQRDownloadPage({super.key});

  @override
  State<CorporatorQRDownloadPage> createState() =>
      _CorporatorQRDownloadPageState();
}

class _CorporatorQRDownloadPageState
    extends State<CorporatorQRDownloadPage> {
  final GlobalKey qrKey = GlobalKey();

  String? corporatorId;
  String? url;

  @override
  void initState() {
    super.initState();
    generateQR();
  }

  void generateQR() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      corporatorId = user.uid;

      url =
          "https://shiny-custard-178fe3.netlify.app/?corporatorId=$corporatorId";

      setState(() {});
    }
  }

  Future<void> downloadQR() async {
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3);

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();

      final file =
          File("${directory.path}/corporator_${corporatorId}_qr.png");

      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("QR saved at:\n${file.path}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Corporator QR")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: qrKey,
              child: QrImageView(
                data: url!,
                size: 260,
                backgroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: downloadQR,
              icon: const Icon(Icons.download),
              label: const Text("Download QR"),
            ),
          ],
        ),
      ),
    );
  }
}