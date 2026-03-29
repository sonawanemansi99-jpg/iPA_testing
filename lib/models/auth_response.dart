class AuthResponse {
  final String token;
  final String role;
  final String id; // Add this

  AuthResponse({required this.token, required this.role, required this.id});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data']; 
    return AuthResponse(
      token: data['token'] ?? '',
      role: data['role'] ?? '',
      id: data['id']?.toString() ?? '', 
    );
  }
}