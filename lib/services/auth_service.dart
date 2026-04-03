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
    final url = Uri.parse('${Constants.ngrokBaseUrl}${Constants.loginEndpoint}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username, 
          'password': password,
        }),
      );

      // 1. First, check if the server actually responded with a 200 OK
      if (response.statusCode == 200) {
        // 2. Decode the raw string body into a Dart Map
        final Map<String, dynamic> responseBody = jsonDecode(response.body);

        // 3. NOW you can check for your custom 'success' flag
        if (responseBody['success'] == true) {
          // 4. Pass the DECODED body, not the raw response
          final authData = AuthResponse.fromJson(responseBody);

          print('🔍 DEBUG 1: Token from Backend: ${authData.token}');
          print('🔍 DEBUG 2: ID from Backend: ${authData.id}');

          if (authData.id.isEmpty || authData.id == "null") {
            print('❌ Login Blocked: Backend did not return a valid User ID.');
            return false; 
          }

          // Save to storage
          await _storage.write(key: 'jwt_token', value: authData.token);
          await _storage.write(key: 'user_role', value: authData.role);
          await _storage.write(key: 'user_id', value: authData.id);

          // Verify it actually saved!
          final savedToken = await _storage.read(key: 'jwt_token');
          final savedId = await _storage.read(key: 'user_id');
          print('🔍 DEBUG 3: Token in Storage: $savedToken');
          print('🔍 DEBUG 4: ID in Storage: $savedId');

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