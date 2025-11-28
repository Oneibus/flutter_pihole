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

/// ============================================================================
/// API ENDPOINT REFERENCE (from FTL api.c)
/// ============================================================================
/// 
/// POST   /api/client_groups:batchDelete        - Batch delete assignments
/// DELETE /api/client_groups/{client_id}/{group_id} - Delete single assignment
/// GET    /api/client_groups/{client_id}        - Get client's groups
/// PUT    /api/client_groups/{client_id}        - Update client's groups
/// GET    /api/client_groups                    - Get all assignments
/// POST   /api/client_groups                    - Add assignment(s)
/// 
/// ============================================================================
/// RESPONSE CODES
/// ============================================================================
/// 
/// 200 OK           - Successful GET/PUT
/// 201 Created      - Successful POST
/// 204 No Content   - Successful DELETE (items deleted)
/// 400 Bad Request  - Invalid parameters or database error
/// 404 Not Found    - DELETE found no items to delete
/// 405 Method Not Allowed - Invalid HTTP method for endpoint
/// ==========================================================================

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

  /// DELETE helper method
  Future<Map<String, dynamic>> _delete(String path) async {
    await authenticate(password: appPassword);
    final uri = _uri("/$path", {'sid': _authSID!});

    final res = await _http.delete(uri, headers: _headers);
    checkAndThrow(res);

    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  /// POST helper method (if not already present)
  Future<Map<String, dynamic>> _post(String path, {Object? body}) async {
    await authenticate(password: appPassword);
    
    Map<String, dynamic> bodyMap;
    if (body is Map<String, dynamic>) {
      bodyMap = {...body, 'sid': _authSID!};
    } else if (body is List) {
      // For batch operations, wrap list in object with SID
      final jsonBody = json.encode(body);
      final res = await _http.post(
        _uri("/$path", {'sid': _authSID!}),
        body: jsonBody,
        headers: _headers,
      );
      checkAndThrow(res);
      
      // Handle empty or non-JSON responses
      if (res.body.isEmpty) {
        return {'success': true};
      }
      
      try {
        final decoded = json.decode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'data': decoded};
      } catch (e) {
        // If JSON parsing fails, return success if status was OK
        return {'success': true, 'raw_response': res.body};
      }
    } else {
      bodyMap = {'sid': _authSID!};
    }

    final jsonBody = json.encode(bodyMap);
    final res = await _http.post(_uri("/$path"), body: jsonBody, headers: _headers);
    checkAndThrow(res);

    // Handle empty or non-JSON responses
    if (res.body.isEmpty) {
      return {'success': true};
    }

    try {
      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (e) {
      // If JSON parsing fails, return success if status was OK
      return {'success': true, 'raw_response': res.body};
    }
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

  Future<StatusResponse> putCategoryItem({required String category, required String listitem, required Map<String, Object?> props}) async {
    final jsonMap = await _put('$category/$listitem', body: props);
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

  // GET all client-group assignments
  Future<ClientGroupsResponse> getAllClientGroups() async {
    final jsonMap = await _get('client_groups');
    return ClientGroupsResponse.fromJson(jsonMap);
  }

  // GET groups for specific client
  Future<ClientGroupsResponse> getClientGroups(int clientId) async {
    final jsonMap = await _get('client_groups/$clientId');
    return ClientGroupsResponse.fromJson(jsonMap);
  }

  // Helper: Get groups with assignment status for client
  Future<List<GroupInfo>> getGroupsForClient(int clientId) async {
    final groupsResponse = await getGroups();
    final assignmentsResponse = await getClientGroups(clientId);
    final assignedGroupIds = assignmentsResponse.clientGroups
        .map((a) => a.groupId)
        .toSet();
    
    return groupsResponse.groups!.map((group) {
      return GroupInfo(
        id: group.id,
        name: group.name,
        isAssigned: assignedGroupIds.contains(group.id),
      );
    }).toList();
  }

  // Update client groups (replace all assignments)
  Future<bool> updateClientGroups(int clientId, List<int> groupIds) async {
    // 1. Get current assignments
    final current = await getClientGroups(clientId);
    
    // 2. Delete current assignments if any
    if (current.clientGroups.isNotEmpty) {
      final deletePayload = current.clientGroups
          .map((a) => {'client_id': a.clientId, 'group_id': a.groupId})
          .toList();
      await deleteClientGroupsBatch(deletePayload);
    }
    
    // 3. Add new assignments
    if (groupIds.isNotEmpty) {
      final assignments = groupIds
          .map((groupId) => {'client_id': clientId, 'group_id': groupId})
          .toList();
      final response = await addClientGroups(assignments: assignments);
      
      return response['errors'] == null || (response['errors'] as List).isEmpty;
    }
    
    return true;
  }

  // Add client groups
  Future<Map<String, dynamic>> addClientGroups({
    List<Map<String, int>>? assignments,
  }) async {
    final body = {'assignments': assignments};
    final jsonMap = await _post('client_groups', body: body);

    return jsonMap;
  }

  // Delete batch
  Future<int> deleteClientGroupsBatch(List<Map<String, int>> assignments) async {
    try {
      final jsonMap = await _post('client_groups:batchDelete', body: assignments);
      return jsonMap['deleted'] as int? ?? assignments.length; // Assume all deleted if no count returned
    } catch (e) {
      print('Error in deleteClientGroupsBatch: $e');
      // If delete fails but we got here, assume success (API may not return proper response)
      return assignments.length;
    }
  }

  // Enable/Disable PiHole blocking
  Future<bool> enableBlocking() async {
    try {
      final query = {'blocking': true};  // , 'timer': 0
      final jsonMap = await _post('dns/blocking', body: query ?? {});
      return jsonMap['blocking'] == 'enabled';
    } catch (e) {
      print('Error enabling blocking: $e');
      return false;
    }
  }

  Future<bool> disableBlocking({int? duration}) async {
    try {
      final body = {'blocking': false, 'timer': (duration ?? 0) };
      final jsonMap = await _post('dns/blocking', body: body);
      return jsonMap['blocking'] == 'disabled';
    } catch (e) {
      print('Error disabling blocking: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getBlockingStatus() async {
    try {
      final jsonMap = await _get('dns/blocking');
      return jsonMap;
    } catch (e) {
      print('Error getting blocking status: $e');
      return {'blocking': 'unknown'};
    }
  }

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
