import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final String message;
  final int? code;
  ApiException(this.message, {this.code});
  @override
  String toString() => message;
}

class Api {
  static String? token;
  static const _timeout = Duration(seconds: 25);

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('${ApiConfig.baseUrl}/$path');
    return query == null || query.isEmpty ? u : u.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _handle(http.Response res) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respons server tidak valid', code: res.statusCode);
    }
    if (res.statusCode >= 400 || body['success'] == false) {
      throw ApiException('${body['message'] ?? 'Terjadi kesalahan'}', code: res.statusCode);
    }
    return body;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    try {
      final res = await http.get(_uri(path, query), headers: _headers).timeout(_timeout);
      return await _handle(res);
    } on http.ClientException {
      throw ApiException('Tidak bisa terhubung ke server');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Koneksi bermasalah');
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(_uri(path), headers: _headers, body: jsonEncode(body)).timeout(_timeout);
      return await _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Koneksi bermasalah');
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body, {Map<String, String>? query}) async {
    try {
      final res = await http.put(_uri(path, query), headers: _headers, body: jsonEncode(body)).timeout(_timeout);
      return await _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Koneksi bermasalah');
    }
  }

  Future<Map<String, dynamic>> delete(String path, {Map<String, String>? query}) async {
    try {
      final res = await http.delete(_uri(path, query), headers: _headers).timeout(_timeout);
      return await _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Koneksi bermasalah');
    }
  }

  /// Upload bytes — aman di web (tidak pakai dart:io File).
  Future<Map<String, dynamic>> postMultipartBytes(
    String path,
    Map<String, String> fields, {
    required String fileField,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _uri(path));
      if (token != null && token!.isNotEmpty) req.headers['Authorization'] = 'Bearer $token';
      req.fields.addAll(fields);
      req.files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      return await _handle(res);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Koneksi bermasalah');
    }
  }

  Future<Map<String, dynamic>> uploadBytes(List<int> bytes, String filename) =>
      postMultipartBytes('upload.php', {}, fileField: 'file', bytes: bytes, filename: filename);

  String fotoUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http')) return filename;
    return '${ApiConfig.uploadsUrl}/$filename';
  }
}
