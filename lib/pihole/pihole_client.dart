import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dartssh2/dartssh2.dart' as ssh;
import 'api_models.dart';
import 'system_events.dart';

class PiHoleHttpException implements Exception {
  final int statusCode;
  final String body;
  final String path;

  PiHoleHttpException(this.statusCode, this.body, this.path);

  @override
  String toString() { 
    return 'HTTP $statusCode for $path: $body'; 
  }
}

class PiHoleClient {
  final String hostname;
  final String _baseUrl;
  final String sysAdminAccount;
  final String appPassword;
  final String sysPassword;
  final http.Client _http;
  final Map<String, String> _headers;
  String? _authSID;
  final SystemEventService? systemEventService;

  PiHoleClient({
    required this.hostname,
    required this.sysAdminAccount,
    required this.appPassword,
    required this.sysPassword,
    this.systemEventService,
    http.Client? httpClient,
    Map<String, String>? defaultHeaders,
  })  : _http = httpClient ?? http.Client(),
        _baseUrl = 'http://$hostname/api',
        _headers = {
          'Accept': 'application/json',
          ...?defaultHeaders,
        };

  void checkAndThrow(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _authSID = null;
      throw PiHoleHttpException(res.statusCode, res.body, res.request?.url.path ?? '');
    }
  }

  // If your API uses session cookies or CSRF:
  void setSession({String? cookie, String? csrfHeader, String? csrfToken}) {
    if (cookie != null) _headers['Cookie'] = cookie;
    if (csrfHeader != null && csrfToken != null) {
      _headers[csrfHeader] = csrfToken;
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  // Auth (adjust endpoint to match your server)
  Future<http.Response> authenticate({required String password}) async {
    if (_authSID != null) return http.Response('OK', 200 );

    final jsonBody = json.encode({'password': password});
    final res = await _http.post(Uri.parse('$_baseUrl/auth'), body: jsonBody, headers: _headers);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw PiHoleHttpException(res.statusCode, res.body, '/auth');
    }

    final authResponse = AuthResponse.fromJson(json.decode(res.body));
    _authSID = authResponse.session?.sid;

    return res;
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, String>? query}) async {
    await authenticate(password: appPassword);
    query = {...?query, 'sid': _authSID!};

    final res = await _http.get(_uri("/$path", query), headers: _headers);
    checkAndThrow(res);

    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    // Wrap non-object JSON into an object for model parsers expecting a map.
    return {'data': decoded};
  }

  Future<Map<String, dynamic>> _put(String path, {Map<String, Object?>? body}) async {
    await authenticate(password: appPassword);
    body = {...?body, 'sid': _authSID!};

    final jsonBody = json.encode(body, toEncodable: (object) => object.toString());

    final res = await _http.put(_uri("/$path"), body: jsonBody, headers: _headers);
    checkAndThrow(res);

    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    // Wrap non-object JSON into an object for model parsers expecting a map.
    return {'data': decoded};
  }

  Future<StatusResponse> putCategoryItem({required String category, required String group, required Map<String, Object?> props}) async {
    final jsonMap = await _put('$category/$group', body: props);
    return StatusResponse.fromJson(jsonMap);
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

  // static ssh.SSHClient? sshClient;

  Future<bool> executeSSHCommand(String command) async {
    ssh.SSHClient? sshClient;
    try {
      sshClient = ssh.SSHClient(
        await ssh.SSHSocket.connect(hostname, 22), 
        username: sysAdminAccount, 
        onPasswordRequest: () => sysPassword
      );
      
      await sshClient.authenticated;
      
      print('Executing SSH command: sudo -S $command');
      
      // Use shell with -c flag and pipe password directly
      final session = await sshClient.execute(
        "/bin/sh -c 'printf \"$sysPassword\\n\" | sudo -S $command'"
      );
      
      // Collect output from the session
      final output = await session.stdout.map(utf8.decode).join();
      final errors = await session.stderr.map(utf8.decode).join();
      
      print('SSH command stdout: $output');
      if (errors.isNotEmpty) print('SSH command stderr: $errors');
      
      final exitCode = await session.exitCode;
      print('SSH command exit code: $exitCode');
      
      return exitCode == 0;
    } catch (e, stackTrace) {
      print('SSH command error: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      sshClient?.close();
    }
  } 

  Future<bool> restartDNS() async => executeSSHCommand('systemctl restart pihole-FTL');
  Future<bool> flushNetworkTable() async => executeSSHCommand('pihole restartdns reload-lists');
  
  /// Reboot system with optional event monitoring
  Future<bool> rebootSystem() async {
    _authSID = null;
    if (systemEventService != null) {
      return await systemEventService!.executeRebootWithMonitoring(
        rebootCommand: () => executeSSHCommand('reboot'),
        healthCheck: checkHealth,
      );
    } else {
      return executeSSHCommand('reboot');
    }
  }

  /// Check if the PiHole API is responding (health check)
  Future<bool> checkHealth() async {
    try {
      final res = await authenticate(password: appPassword).timeout(const Duration(seconds: 5));
      return res.statusCode == 200 || res.statusCode == 401; // 401 means service is up but not authenticated
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  void close() => _http.close();
}