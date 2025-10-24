import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_models.dart';

class PiHoleHttpException implements Exception {
  final int statusCode;
  final String body;
  final String path;

  PiHoleHttpException(this.statusCode, this.body, this.path);

  @override
  String toString() => 'HTTP $statusCode for $path: $body';
}

class PiHoleClient {
  final String baseUrl;
  final String appPassword;
  final http.Client _http;
  final Map<String, String> _headers;
  String? _authSID;

  PiHoleClient({
    required this.baseUrl,
    required this.appPassword,
    http.Client? httpClient,
    Map<String, String>? defaultHeaders,
  })  : _http = httpClient ?? http.Client(),
        _headers = {
          'Accept': 'application/json',
          ...?defaultHeaders,
        };

  // If your API uses session cookies or CSRF:
  void setSession({String? cookie, String? csrfHeader, String? csrfToken}) {
    if (cookie != null) _headers['Cookie'] = cookie;
    if (csrfHeader != null && csrfToken != null) {
      _headers[csrfHeader] = csrfToken;
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  // Auth (adjust endpoint to match your server)
  Future<String> authenticate({required String password}) async {
    if (_authSID != null) return _authSID!;

    final jsonBody = json.encode({'password': password});
    final res = await _http.post(Uri.parse('$baseUrl/auth'), body: jsonBody, headers: _headers);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw PiHoleHttpException(res.statusCode, res.body, '/auth');
    }

    final authResponse = AuthResponse.fromJson(json.decode(res.body));
    return authResponse.session?.sid ?? "";
  }


  Future<Map<String, dynamic>> _get(String path, {Map<String, String>? query}) async {
    _authSID ??= (await authenticate(password: appPassword));
    query = {...?query, 'sid': _authSID!};

    final res = await _http.get(_uri("/$path", query), headers: _headers);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw PiHoleHttpException(res.statusCode, res.body, path);
    }

    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    // Wrap non-object JSON into an object for model parsers expecting a map.
    return {'data': decoded};
  }

  Future<GroupsResponse> getGroups() async {
    final jsonMap = await _get('groups');
    return GroupsResponse.fromJson(jsonMap);
  }

  Future<ClientsResponse> getClients() async {
    final jsonMap = await _get('clients');
    return ClientsResponse.fromJson(jsonMap);
  }

  Future<DomainsResponse> getDomains() async {
    final jsonMap = await _get('domains');
    return DomainsResponse.fromJson(jsonMap);
  }

  Future<NetworkResponse> getNetworks() async {
    final jsonMap = await _get('networks');
    return NetworkResponse.fromJson(jsonMap);
  }

  Future<NetworkDevicesResponse> getNetworkDevices() async {
    final jsonMap = await _get('network/devices');
    return NetworkDevicesResponse.fromJson(jsonMap);
  }

  Future<QueriesResponse> getQueries({int? since, int? until}) async {
    final qp = <String, String>{};
    if (since != null) qp['since'] = '$since';
    if (until != null) qp['until'] = '$until';
    final jsonMap = await _get('queries', query: qp.isEmpty ? null : qp);
    return QueriesResponse.fromJson(jsonMap);
  }

  void close() => _http.close();
}