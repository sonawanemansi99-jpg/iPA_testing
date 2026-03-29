import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/constants.dart';
class SuperadminServices {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> uploadLivePhotoToCloudinary(File imageFile) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/${Constants.cloudName}/image/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = Constants.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseData);
      return jsonMap['secure_url']; // Return the Cloudinary URL
    } else {
      throw Exception("Failed to upload image to Cloudinary");
    }
  }

  Future<void> registerCorporator({
    required String nickname,
    required String name,
    required String mobileNo,
    required String email,
    required String password,
    required String livePhotoUrl,
    required String area,
    required String adharNo,
  }) async {
    final url = Uri.parse('${Constants.baseUrl}/admins'); // Assuming your controller maps to /admins

    // 1. Fetch JWT and the logged-in SuperAdmin's ID from secure storage
    final String? token = await _storage.read(key: 'jwt_token');
    final String? superAdminIdStr = await _storage.read(key: 'user_id');

    if (token == null || superAdminIdStr == null) {
      throw Exception("Authentication error. Please log in again.");
    }

    final int parsedSuperAdminId = int.tryParse(superAdminIdStr) ?? 1;

    // 2. Prepare the payload exactly matching the Spring Boot DTO
    final Map<String, dynamic> payload = {
      "nickname": nickname,
      "name": name,
      "mobileNumber": mobileNo,
      "email": email,
      "password": password,
      "livePhotoUrl": livePhotoUrl,
      "area": area,
      "adharNo": adharNo,
      "superAdminId": parsedSuperAdminId, // Converted to Long for Spring Boot
    };

    // 3. Make the API Call with the JWT
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // PASSING THE JWT HERE!
      },
      body: jsonEncode(payload),
    );

    // 4. Handle the Response
    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        return; // Success!
      } else {
        throw Exception(responseData['message'] ?? "Failed to create corporator");
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? "Server error: ${response.statusCode}");
    }
  }
}