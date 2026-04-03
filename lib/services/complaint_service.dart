import 'dart:convert';
import 'package:corporator_app/core/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ComplaintService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Fetch Complaints (Smart Routing) ──
  Future<List<Map<String, dynamic>>> fetchComplaints({int? adminId}) async {
    final String? token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception("Authentication token missing.");

    final String endpoint = adminId != null 
        ? '${Constants.ngrokBaseUrl}/complaints/admin/$adminId'
        : '${Constants.ngrokBaseUrl}${Constants.complaintsEndpoint}';

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
      throw Exception("Failed to fetch complaints");
    } catch (e) {
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