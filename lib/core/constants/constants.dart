class Constants {
  // Because of adb reverse, localhost works on your physical phone!
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  // Auth Endpoints
  static const String loginEndpoint = '/auth/login';
  
  // Complaint Endpoints
  static const String complaintsEndpoint = '/complaints';

  static const String cloudName = "dq18qyvol";
  static const String uploadPreset = "flutter_unsigned";
}