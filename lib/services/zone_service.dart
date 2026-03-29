import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZoneService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Fetch Zones for the Current Admin ──
  Future<List<Map<String, dynamic>>> fetchMyZones() async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception("Authentication token missing. Please log in again.");
    }

    // Perfectly constructed URL using your Constants
    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.zoneEndpoint}');

    try {
      debugPrint("Fetching My Zones from: $url");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420', 
        },
      );

      debugPrint("Response Status (Zones): ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception(responseData['message'] ?? "Failed to fetch zones");
        }
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Zone Fetch Error: $e");
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── CREATE ZONE WITH AREAS ──
  Future<void> createZoneWithAreas(String zoneName, List<Map<String, String>> areas) async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null) throw Exception("Authentication token missing.");

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.zoneEndpoint}');

    final payload = {
      "name": zoneName,
      "newAreas": areas,
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
      throw Exception(responseData['message'] ?? "Failed to create Zone.");
    }
  }

  // ── Fetch UNASSIGNED Zones for Assignment ──
  Future<List<dynamic>> fetchUnassignedZones() async {
    final String? token = await _storage.read(key: 'jwt_token');
    
    if (token == null) throw Exception("Authentication token missing.");
    
    final url = Uri.parse('${Constants.ngrokBaseUrl}/zones/unassigned'); 

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