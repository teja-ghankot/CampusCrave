import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class AuthService {
  final _baseUrl = 'https://campcrave-backend.onrender.com'; // For Android emulator. Use localhost for iOS/web.
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
      final data = jsonDecode(response.body);
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'userId', value: data['userId']);
      await _storage.write(key:'phonenumber',value: data['phonenumber']);
      await _storage.write(key: 'role', value: data['role']); // Saving the role
      return data['role']; // Return 'student' or 'canteen'
    } else {
      // final responseBody = jsonDecode(response.body);
      return null;
    }
  }



  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }
}
