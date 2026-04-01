import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZoneService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Fetch Zones (Smart Routing) ──
  Future<List<Map<String, dynamic>>> fetchMyZones({int? adminId}) async {
    final String? token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception("Authentication token missing.");

    // SMART ROUTING: If adminId is provided, hit the specific admin endpoint. Otherwise, hit the default.
    final String endpoint = adminId != null 
        ? '${Constants.ngrokBaseUrl}${Constants.zoneEndpoint}/admin/$adminId'
        : '${Constants.ngrokBaseUrl}${Constants.zoneEndpoint}';

    final url = Uri.parse(endpoint);

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': '69420',
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return List<Map<String, dynamic>>.from(responseData['data']);
        }
      }
      throw Exception("Failed to fetch zones");
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── CREATE ZONE WITH AREAS ──
  Future<void> createZoneWithAreas(String zoneName, List<Map<String, String>> areas, {int? adminId}) async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null) throw Exception("Authentication token missing.");

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.zoneEndpoint}');

    final payload = {
      "name": zoneName,
      "newAreas": areas,
    };
    
    // Add adminId to the payload if it was provided (Super Admin God Mode)
    if (adminId != null) {
      payload["adminId"] = adminId;
    }

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
      throw Exception(responseData['message'] ?? "Failed to create Zone.");
    }
  }

  // ── Fetch UNASSIGNED Zones for Assignment ──
  Future<List<dynamic>> fetchUnassignedZones() async {
    final String? token = await _storage.read(key: 'jwt_token');
    
    if (token == null) throw Exception("Authentication token missing.");
    
    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.zoneEndpoint}/unallocated'); 

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
        return responseData['data'] as List<dynamic>;
      }
    }
    throw Exception("Failed to load available Zones.");
  }

  // ── Update Zone ──
  Future<void> updateZone(String zoneId, Map<String, dynamic> payload) async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null) throw Exception("Authentication error. Please log in again.");

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.zoneEndpoint}/$zoneId');

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
      throw Exception(responseData['message'] ?? "Failed to update Zone");
    }
  }
}