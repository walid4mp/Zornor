import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl();

  final String baseUrl;
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> getJson(String path) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers).timeout(AppConfig.httpClientTimeout);
      return _decode(response);
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال بالخادم.');
    } on SocketException {
      throw ApiException('تعذر الوصول إلى الخادم. تحقق من الإنترنت أو إعدادات الخادم.');
    } on HttpException {
      throw ApiException('حدث خطأ في الاتصال بالخادم.');
    }
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
          .timeout(AppConfig.httpClientTimeout);
      return _decode(response);
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال بالخادم.');
    } on SocketException {
      throw ApiException('تعذر الوصول إلى الخادم. تحقق من الإنترنت أو إعدادات الخادم.');
    } on HttpException {
      throw ApiException('حدث خطأ في الاتصال بالخادم.');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } on FormatException {
      throw ApiException('استجابة غير صالحة من الخادم.', statusCode: response.statusCode);
    }
    final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
    if (response.statusCode >= 400) {
      throw ApiException(
        data['message']?.toString() ?? 'Request failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
