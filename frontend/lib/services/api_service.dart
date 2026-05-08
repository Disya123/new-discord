import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndiscord/config/api_config.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final headers = await _headers();
    return http.get(Uri.parse('${ApiConfig.apiUrl}$path'), headers: headers);
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    return http.post(
      Uri.parse('${ApiConfig.apiUrl}$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    return http.put(
      Uri.parse('${ApiConfig.apiUrl}$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String path) async {
    final headers = await _headers();
    return http.delete(Uri.parse('${ApiConfig.apiUrl}$path'), headers: headers);
  }

  Future<Map<String, dynamic>> postJson(String path, {Map<String, dynamic>? body}) async {
    final response = await post(path, body: body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await get(path);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  String get message {
    try {
      final data = jsonDecode(body);
      return data['detail'] ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
