import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminGroupService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final String? token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception("Authentication token not found");
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': '69420',
    };
  }

  // ── 1. Fetch All Groups ──
  Future<List<dynamic>> getAllGroups() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/admin-groups'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    throw Exception("Failed to fetch groups");
  }

  // ── 2. Fetch Single Group by ID (NEW) ──
  Future<Map<String, dynamic>> getGroupById(int groupId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/admin-groups/$groupId'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    throw Exception("Failed to fetch group details");
  }

  // ── 3. Toggle Status ──
  Future<void> toggleGroupStatus(int groupId, bool isActive) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('${Constants.ngrokBaseUrl}/admin-groups/$groupId/status?active=$isActive'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception("Failed to update group status");
  }

  // ── 4. Remove Admin ──
  Future<void> removeAdminFromGroup(int groupId, int adminId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('${Constants.ngrokBaseUrl}/admin-groups/$groupId/admins/$adminId'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)['message'] ?? "Failed to remove admin");
  }

  // ── 5. Assign Admins (NEW) ──
  Future<void> assignAdminsToGroup(int groupId, List<int> adminIds) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.ngrokBaseUrl}/admin-groups/$groupId/admins'),
      headers: headers,
      body: jsonEncode(adminIds), // Sending a JSON array of IDs
    );
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)['message'] ?? "Failed to assign admins");
  }

  // ── 6. Update Group Details ──
  Future<void> updateAdminGroup(int groupId, String name, String description) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Constants.ngrokBaseUrl}/admin-groups/$groupId'),
      headers: headers,
      body: jsonEncode({"groupName": name, "description": description}),
    );
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)['message'] ?? "Failed to update group");
  }

  Future<void> createAdminGroup(String name, String description, List<int> existingAdminIds) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.ngrokBaseUrl}/admin-groups'),
      headers: headers,
      body: jsonEncode({
        "groupName": name,
        "description": description,
        "existingAdminIds": existingAdminIds
      }),
    );
    if (response.statusCode != 201) throw Exception(jsonDecode(response.body)['message'] ?? "Failed to create group");
  }
}