import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZoneSevakService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Fetch Zone Sevaks for Current Admin ──
  Future<List<Map<String, dynamic>>> fetchMyZoneSevaks() async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception("Authentication token missing. Please log in again.");
    }

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.zoneSevakEndpoint}');

    try {
      debugPrint("Fetching Zone Sevaks from: $url");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      debugPrint("Response Status (Zone Sevaks): ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? "Failed to fetch Zone Sevaks");
        }
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Zone Sevak Fetch Error: $e");
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── Create Zone Sevak ──
  Future<void> createZoneSevak({
    required String nickname,
    required String name,
    required String mobileNo,
    required String email,
    required String password,
    required String livePhotoUrl,
    required String adharNo,
    required List<int> zoneIds,
  }) async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null) throw Exception("Authentication error. Please log in again.");

    final url = Uri.parse('${Constants.ngrokBaseUrl}/zone-sevaks');

    // SECURITY UPGRADE: We no longer send 'adminId' from the frontend!
    final Map<String, dynamic> payload = {
      "nickname": nickname,
      "name": name,
      "mobileNumber": mobileNo,
      "email": email,
      "password": password,
      "livePhotoUrl": livePhotoUrl,
      "adharNo": adharNo,
      "zoneIds": zoneIds, 
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': '69420',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? "Failed to create Zone Sevak");
    }
  }

  // ── Update Zone Sevak ──
  Future<void> updateZoneSevak(String sevakId, Map<String, dynamic> payload) async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null) {
      throw Exception("Authentication error. Please log in again.");
    }

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.zoneSevakEndpoint}/$sevakId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': '69420',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['message'] ?? "Failed to update Zone Sevak");
    }
  }
}