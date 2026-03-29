import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/constants.dart';
import '../models/auth_response.dart';

class AuthService {
  // Initialize secure storage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('${Constants.baseUrl}${Constants.loginEndpoint}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username, // Can be email or mobile based on our backend
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // Check our custom 'success' flag from Spring Boot
        if (responseBody['success'] == true) {
          final authData = AuthResponse.fromJson(responseBody);

          // Save the token and role securely on the device
          await _storage.write(key: 'jwt_token', value: authData.token);
          await _storage.write(key: 'user_role', value: authData.role);
          await _storage.write(key: 'user_id', value: authData.id);

          debugPrint('Login Success! Role: ${authData.role}');
          return true;
        }
      }
      
      // If we reach here, it's a 401 or 400 error
      final errorBody = jsonDecode(response.body);
      debugPrint('Login Failed: ${errorBody['message']}');
      return false;

    } catch (e) {
      debugPrint('Network/Server Error: $e');
      return false;
    }
  }

  // Helper method to get the token later when fetching complaints
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Helper method to log out
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}