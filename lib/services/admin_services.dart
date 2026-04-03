import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminServices {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Fetch Profile Data ──
  Future<Map<String, dynamic>> getCorporatorProfile() async {
    final String? token = await _storage.read(key: 'jwt_token');
    final String? userIdStr = await _storage.read(key: 'user_id');

    if (token == null || userIdStr == null || userIdStr.trim().isEmpty) {
      throw Exception("Authentication token missing. Please log in again.");
    }

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.adminEndpoint}/$userIdStr');

    try {
      debugPrint("Fetching Profile from: $url");
      debugPrint("Using Token: Bearer ${token.substring(0, 15)}...");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data']; 
        } else {
          throw Exception(responseData['message'] ?? "Failed to fetch profile");
        }
      } else {
        // This will show us if it's a 403 (Security) or 404 (Not Found)
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      // Expose the raw error to the UI!
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // Helper method for Logout
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}