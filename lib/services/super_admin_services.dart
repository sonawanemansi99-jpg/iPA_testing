import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SuperAdminService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Helper to inject tokens and ngrok headers ──
  Future<Map<String, String>> _getHeaders() async {
    final String? token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception("Authentication token not found");
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': '69420',
    };
  }

  // ── Register Corporator / Admin ──
  Future<void> registerCorporator({
    required String nickname,
    required String name,
    required String mobileNo,
    required String email,
    required String password,
    required String livePhotoUrl,
    required String area,
    required String adharNo,
    required bool autoCreateGroup,    
    int? existingAdminGroupId,        
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Constants.ngrokBaseUrl}/admins'), 
      headers: headers,
      body: jsonEncode({
        "nickname": nickname,
        "name": name,
        "mobileNumber": mobileNo,
        "email": email,
        "password": password,
        "livePhotoUrl": livePhotoUrl,
        "area": area.isEmpty ? null : area, 
        "adharNo": adharNo,
        "autoCreateGroup": autoCreateGroup,
        "existingAdminGroupId": existingAdminGroupId,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      debugPrint("BACKEND ERROR BODY: ${response.body}");
      // Handle Spring Boot validation errors safely
      if (errorData.containsKey('errors') && errorData['errors'] != null) {
        final Map<String, dynamic> fieldErrors = errorData['errors'];
        final errorMessage = fieldErrors.entries.map((e) => "${e.key}: ${e.value}").join('\n');
        throw Exception(errorMessage);
      }
      throw Exception(errorData['message'] ?? "Registration failed");
    }
  }

  // ── Fetch Admin Groups for Dropdown ──
  Future<List<Map<String, dynamic>>> getAdminGroupsForDropdown() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.ngrokBaseUrl}/admin-groups/dropdown'),
        headers: headers,
      );

      debugPrint("Group Dropdown Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['data'];
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Error in getAdminGroupsForDropdown: $e");
    }
    return [];
  }

  // ── Create New Super Admin ──
  Future<void> createSuperAdmin(Map<String, dynamic> payload) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.ngrokBaseUrl}/super-admins'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        if (errorData.containsKey('errors') && errorData['errors'] != null) {
          final Map<String, dynamic> fieldErrors = errorData['errors'];
          final errorMessage = fieldErrors.entries.map((e) => "${e.key}: ${e.value}").join('\n');
          throw Exception(errorMessage);
        }
        throw Exception(errorData['message'] ?? "Failed to create Super Admin.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── 1. Fetch All Admins ──
  Future<List<dynamic>> getAllAdmins() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.ngrokBaseUrl}/admins'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch admins: $e");
    }
  }

  // ── 2. Toggle Admin Status ──
  Future<bool> toggleAdminStatus(int adminId, bool newStatus) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${Constants.ngrokBaseUrl}/admins/$adminId/status?active=$newStatus'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to update status. Server responded with ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  // ── 3. Fetch Admin-Specific Scoped Data (For Inspector View) ──
  Future<List<dynamic>> getAdminSpecificZones(int adminId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/zones/admin/$adminId'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception("Failed to fetch scoped zones");
  }

  Future<List<dynamic>> getAdminSpecificComplaints(int adminId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/complaints/admin/$adminId'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception("Failed to fetch scoped complaints");
  }

  Future<List<dynamic>> getAdminSpecificSevaks(int adminId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/zone-sevaks/admin/$adminId'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception("Failed to fetch scoped sevaks");
  }

  // ── Fetch ALL Global Zones ──
  Future<List<dynamic>> getAllGlobalZones() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.ngrokBaseUrl}/zones'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      } else {
        throw Exception("Failed to fetch global zones.");
      }
    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  // ── Delete Zone (Super Admin Only) ──
  Future<bool> deleteZone(int zoneId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${Constants.ngrokBaseUrl}/zones/$zoneId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Failed to delete zone.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── Fetch ALL Global Complaints ──
  Future<List<dynamic>> getAllGlobalComplaints() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.ngrokBaseUrl}/complaints'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      } else {
        throw Exception("Failed to fetch global complaints.");
      }
    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  // ── Fetch ALL Global Sevaks ──
  Future<List<dynamic>> getAllGlobalSevaks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.ngrokBaseUrl}/zone-sevaks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'] ?? [];
      } else {
        throw Exception("Failed to fetch global sevaks.");
      }
    } catch (e) {
      throw Exception("Network Error: $e");
    }
  }

  // ── Delete Zone Sevak (Super Admin Only) ──
  Future<bool> deleteZoneSevak(int sevakId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${Constants.ngrokBaseUrl}/zone-sevaks/$sevakId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? "Failed to delete sevak.");
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── Fetch ALL Super Admins ──
  Future<List<dynamic>> getAllSuperAdmins() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/super-admins'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception("Failed to fetch Super Admins.");
  }

  // ── Toggle Super Admin Status ──
  Future<void> toggleSuperAdminStatus(int id, bool newStatus) async {
    final headers = await _getHeaders();
    final response = await http.patch(Uri.parse('${Constants.ngrokBaseUrl}/super-admins/$id/status?active=$newStatus'), headers: headers);
    if (response.statusCode != 200) throw Exception("Failed to update status.");
  }

  // ── Fetch Admins by Super Admin ID ──
  Future<List<dynamic>> getAdminsBySuperAdmin(int superAdminId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/admins/super-admin/$superAdminId'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception("Failed to fetch assigned Admins.");
  }

  Future<void> updateAdmin(int id, Map<String, dynamic> payload) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Constants.ngrokBaseUrl}/admins/$id'),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) throw Exception("Update failed: ${response.body}");
  }

  Future<Map<String, dynamic>> getAdminById(int adminId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${Constants.ngrokBaseUrl}/admins/$adminId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    throw Exception("Failed to fetch admin details");
  }
}