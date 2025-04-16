import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class AuthService {
  final _baseUrl = 'http://10.0.2.2:3000'; // For Android emulator. Use localhost for iOS/web.
  final _storage = const FlutterSecureStorage();

  Future<String?> registerUser(String phone, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'token', value: data['token']);
      return null;
    } else {
      return jsonDecode(response.body)['message'];
    }
  }

  Future<String?> loginUser(String mobileNumber, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobileNumber': mobileNumber,  // Updated field to 'mobileNumber'
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return null; // Successful login
    } else {
      final responseBody = jsonDecode(response.body);
      return responseBody['message']; // Return the error message from the server
    }
  }


  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }
}
