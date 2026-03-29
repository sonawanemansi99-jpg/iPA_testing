class Constants {
  // Because of adb reverse, localhost works on your physical phone!
  static const String baseUrl = 'http://localhost:8080/api/v1';
  
  // Auth Endpoints
  static const String loginEndpoint = '/auth/login';
  
  // Complaint Endpoints
  static const String complaintsEndpoint = '/complaints';

  static const String adminEndpoint = '/admins';

  static const String zoneEndpoint = '/zones';

  static const String zoneSevakEndpoint = '/zone-sevaks';

  static const String cloudName = "dq18qyvol";
  static const String uploadPreset = "flutter_unsigned";

  static const String ngrokBaseUrl = "https://christiana-plantlike-melodie.ngrok-free.dev/api/v1";
}