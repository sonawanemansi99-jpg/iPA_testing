import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ComplaintService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Fetch Complaints for the Corporator's Group ──
  Future<List<Map<String, dynamic>>> fetchComplaints() async {
    final String? token = await _storage.read(key: 'jwt_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception("Authentication token missing. Please log in again.");
    }

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.complaintsEndpoint}');

    try {
      debugPrint("Fetching Complaints from: $url");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': '69420',
        },
      );

      debugPrint("Response Status (Complaints): ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          // Return raw maps instead of a rigid model
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception(responseData['message'] ?? "Failed to fetch complaints");
        }
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("Complaint Fetch Error: $e");
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ── 1. Update Basic Status (In Progress, Deferred, Unresolved) ──
  Future<void> updateComplaintStatus(String complaintId, String newStatus) async {
    final String? token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception("Authentication token missing.");

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.complaintsEndpoint}/$complaintId/status?status=$newStatus');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': '69420',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? "Failed to update status.");
    }
  }

  // ── 2. Resolve Complaint (Strict Validation for COMPLETED) ──
  Future<void> resolveComplaint(String complaintId, String resolutionImageUrl, String? resolutionDescription, String? voiceNoteUrl) async {
    final String? token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception("Authentication token missing.");

    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.complaintsEndpoint}/$complaintId/resolve');

    final payload = {
      "resolutionImageUrl": resolutionImageUrl,
      "resolutionDescription": resolutionDescription,
      "voiceNoteUrl": voiceNoteUrl,
    };

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': '69420',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? "Failed to resolve complaint.");
    }
  }
}