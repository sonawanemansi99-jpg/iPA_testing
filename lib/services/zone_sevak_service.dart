import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZoneSevakService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Fetch Logged-In Zone Sevak Profile ──
  Future<Map<String, dynamic>> getZoneSevakProfile() async {
    final String? token = await _storage.read(key: 'jwt_token');
    final String? userIdStr = await _storage.read(key: 'user_id');

    if (token == null || userIdStr == null) {
      throw Exception("Authentication data missing. Please log in again.");
    }

    // Call the GET /{id} endpoint on the controller
    final url = Uri.parse('${Constants.ngrokBaseUrl}/zone-sevaks/$userIdStr');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'];
        }
      } else {
        debugPrint("PROFILE FETCH FAILED. Status: ${response.statusCode}");
        debugPrint("Body: ${response.body}");
        throw Exception("Server returned ${response.statusCode}");
      }
      throw Exception("Failed to load profile data.");
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── Fetch Zone Sevaks (List) ──
  Future<List<Map<String, dynamic>>> fetchMyZoneSevaks({int? adminId}) async {
    final String? token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception("Authentication token missing.");
    final String endpoint = adminId != null
        ? '${Constants.ngrokBaseUrl}/zone-sevaks/admin/$adminId' // The Super Admin Inspector View
        : '${Constants.ngrokBaseUrl}/zone-sevaks/me'; // The Admin's Own Dashboard

    final url = Uri.parse(endpoint);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      throw Exception("Failed to fetch Zone Sevaks");
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── Create Zone Sevak ──
  Future<void> createZoneSevak({
    required String nickname,
    required String name,
    required String mobileNumber,
    required String email,
    required String password,
    required String livePhotoUrl,
    required String adharNo,
    required List<int> zoneIds,
  }) async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null)
      throw Exception("Authentication error. Please log in again.");

    final url = Uri.parse(
      '${Constants.ngrokBaseUrl}${Constants.zoneSevakEndpoint}',
    );
    final Map<String, dynamic> payload = {
      "nickname": nickname,
      "name": name,
      "mobileNumber": mobileNumber,
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
      debugPrint("RAW BACKEND RESPONSE: ${response.body}");

      final responseData = jsonDecode(response.body);

      if (responseData.containsKey('errors') &&
          responseData['errors'] != null) {
        final Map<String, dynamic> fieldErrors = responseData['errors'];
        final errorMessage = fieldErrors.entries
            .map((e) => "${e.key}: ${e.value}")
            .join('\n');
        throw Exception(errorMessage);
      }
      throw Exception(
        responseData['message'] ??
            "Unknown Server Error: ${response.statusCode}",
      );
    }
  }

  // ── Update Zone Sevak ──
  Future<void> updateZoneSevak(
    String sevakId,
    Map<String, dynamic> payload,
  ) async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null) {
      throw Exception("Authentication error. Please log in again.");
    }

    final url = Uri.parse(
      '${Constants.ngrokBaseUrl}${Constants.zoneSevakEndpoint}/$sevakId',
    );

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
