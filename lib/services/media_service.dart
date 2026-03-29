import 'dart:convert';
import 'dart:io';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:http/http.dart' as http;

class MediaService {
  // ── Upload Any Media (Image or Audio) to Cloudinary ──
  Future<String> uploadMediaToCloudinary(File file, {bool isAudio = false}) async {
    final resourceType = isAudio ? "video" : "image"; // Cloudinary uses 'video' for audio
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/${Constants.cloudName}/$resourceType/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = Constants.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonMap = jsonDecode(responseData);
      return jsonMap['secure_url']; 
    } else {
      throw Exception("Cloudinary upload failed: $responseData");
    }
  }
}