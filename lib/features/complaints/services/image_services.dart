import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

Future<String?> uploadImageToCloudinary(File imageFile) async {
  final cloudName = 'dq18qyvol';       // Your Cloudinary cloud name
  final uploadPreset = 'flutter_unsigned'; // Unsigned preset

  final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  var request = http.MultipartRequest('POST', uri);
  request.fields['upload_preset'] = uploadPreset;
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path, filename: basename(imageFile.path)));

  final response = await request.send();

  if (response.statusCode == 200) {
    final resStr = await response.stream.bytesToString();
    final json = resStr.isNotEmpty ? jsonDecode(resStr) : null;
    return json?['secure_url'];
  } else {
    print('Cloudinary upload failed: ${response.statusCode}');
    return null;
  }
}