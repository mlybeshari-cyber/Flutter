import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';
import '../models/position.dart';
import '../models/session.dart';

// Shërbimi kryesor për komunikimin me Traccar REST API
// Main service for communicating with Traccar REST API

class TraccarService {
  // URL bazë e serverit / Base URL of the server
  String _baseUrl = 'https://demo.traccar.org/api';
  String _username = '';
  String _password = '';

  // Cookies për sesionin / Session cookies
  String? _sessionCookie;

  static const String _prefBaseUrl = 'traccar_base_url';
  static const String _prefUsername = 'traccar_username';
  static const String _prefPassword = 'traccar_password';

  TraccarService();

  // Inicializon shërbimin duke lexuar kredencialet e ruajtura
  // Initializes the service by reading saved credentials
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl =
        prefs.getString(_prefBaseUrl) ?? 'https://demo.traccar.org/api';
    _username = prefs.getString(_prefUsername) ?? '';
    _password = prefs.getString(_prefPassword) ?? '';
  }

  // Ruan kredencialet lokalisht / Saves credentials locally
  Future<void> saveCredentials({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefBaseUrl, baseUrl);
    await prefs.setString(_prefUsername, username);
    await prefs.setString(_prefPassword, password);
    _baseUrl = baseUrl;
    _username = username;
    _password = password;
  }

  // Fshi kredencialet / Clear credentials
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefBaseUrl);
    await prefs.remove(_prefUsername);
    await prefs.remove(_prefPassword);
    _username = '';
    _password = '';
    _sessionCookie = null;
  }

  // Ndërton header-at e autentikimit / Builds authentication headers
  Map<String, String> _buildHeaders({bool includeContentType = false}) {
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    final headers = <String, String>{
      'Authorization': 'Basic $credentials',
      'Accept': 'application/json',
    };
    if (includeContentType) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  // Trajton përgjigjen e serverit / Handles server response
  void _handleCookies(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      // Merr vetëm JSESSIONID / Take only JSESSIONID
      final match = RegExp(r'JSESSIONID=[^;]+').firstMatch(rawCookie);
      if (match != null) {
        _sessionCookie = match.group(0);
      }
    }
  }

  // ─── SESSION ENDPOINTS ────────────────────────────────────────────────────

  /// POST /session — Kyçu / Login
  Future<Session> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    // Normalizo URL / Normalize URL
    final cleanUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // Ruaj kredencialet para kërkesës / Save credentials before request
    await saveCredentials(
        baseUrl: cleanUrl, username: username, password: password);

    final credentials = base64Encode(utf8.encode('$username:$password'));
    final response = await http.post(
      Uri.parse('$cleanUrl/session'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'email': username, 'password': password},
    );

    _handleCookies(response);

    if (response.statusCode == 200) {
      return Session.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Kredencialet janë të gabuara. / Invalid credentials.');
    } else {
      throw Exception(
          'Gabim gjatë kyçjes (${response.statusCode}). / Login error (${response.statusCode}).');
    }
  }

  /// DELETE /session — Shkyçu / Logout
  Future<void> logout() async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/session'),
        headers: _buildHeaders(),
      );
    } catch (_) {
      // Injoro gabimet e daljes / Ignore logout errors
    } finally {
      await clearCredentials();
    }
  }

  /// GET /session — Merr sesionin aktual / Get current session
  Future<Session> getSession() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/session'),
      headers: _buildHeaders(),
    );

    _handleCookies(response);

    if (response.statusCode == 200) {
      return Session.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Sesioni ka skaduar. / Session expired.');
    } else {
      throw Exception(
          'Gabim gjatë marrjes së sesionit (${response.statusCode}). / Session error (${response.statusCode}).');
    }
  }

  // ─── DEVICE ENDPOINTS ─────────────────────────────────────────────────────

  /// GET /devices — Lista e të gjitha pajisjeve / List all devices
  Future<List<Device>> getDevices() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/devices'),
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Device.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Nuk jeni i autentikuar. / Not authenticated.');
    } else {
      throw Exception(
          'Gabim gjatë marrjes së pajisjeve (${response.statusCode}). / Devices error (${response.statusCode}).');
    }
  }

  /// GET /devices/{id} — Merr pajisjen specifike / Get specific device
  Future<Device> getDevice(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/devices/$id'),
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      return Device.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Pajisja nuk u gjet. / Device not found.');
    } else {
      throw Exception(
          'Gabim gjatë marrjes së pajisjes (${response.statusCode}). / Device error (${response.statusCode}).');
    }
  }

  // ─── POSITION ENDPOINTS ───────────────────────────────────────────────────

  /// GET /positions — Merr pozicionet aktuale / Get current positions
  /// Mund të filtrohet me deviceId / Can be filtered by deviceId
  Future<List<Position>> getPositions({int? deviceId}) async {
    final uri = Uri.parse('$_baseUrl/positions').replace(
      queryParameters: deviceId != null
          ? {'deviceId': deviceId.toString()}
          : null,
    );

    final response = await http.get(uri, headers: _buildHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Position.fromJson(json)).toList();
    } else {
      throw Exception(
          'Gabim gjatë marrjes së pozicioneve (${response.statusCode}). / Positions error (${response.statusCode}).');
    }
  }

  /// GET /positions?deviceId={id}&from={ISO8601}&to={ISO8601}
  /// Historiku i pozicioneve / Position history
  Future<List<Position>> getPositionHistory({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse('$_baseUrl/positions').replace(
      queryParameters: {
        'deviceId': deviceId.toString(),
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    final response = await http.get(uri, headers: _buildHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Position.fromJson(json)).toList();
    } else {
      throw Exception(
          'Gabim gjatë marrjes së historikut (${response.statusCode}). / History error (${response.statusCode}).');
    }
  }

  // ─── GETTERS ──────────────────────────────────────────────────────────────

  String get baseUrl => _baseUrl;
  String get username => _username;

  /// Kontrollo nëse ka kredenciale / Check if credentials exist
  bool get hasCredentials => _username.isNotEmpty && _password.isNotEmpty;
}
