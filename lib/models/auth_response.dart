class AuthResponse {
  final String token;
  final String role;

  AuthResponse({required this.token, required this.role});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // We dive into the 'data' wrapper that your Spring Boot backend sends
    final data = json['data']; 
    return AuthResponse(
      token: data['token'] ?? '',
      role: data['role'] ?? '',
    );
  }
}