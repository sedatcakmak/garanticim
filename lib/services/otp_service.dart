import 'package:http/http.dart' as http;

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  static const String _baseUrl = 'https://api.daimapp.com';

  /// Send OTP code to phone number
  /// Returns true if OTP sent successfully
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send_otp'),
        body: {'phone': phoneNumber},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Verify OTP code
  /// Returns true if OTP is valid
  Future<bool> verifyOtp(String phoneNumber, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify_otp'),
        body: {'phone': phoneNumber, 'code': code},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
