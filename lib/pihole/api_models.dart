import 'dart:convert';

T? _asOrNull<T>(dynamic v) => v is T ? v : null;

String _asStringOrEmpty(dynamic v) => v is String ? v : '';

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool? _asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return null;
}

List<int>? _asIntList(dynamic v) {
  if (v is List) {
    return v.map((e) => _asInt(e) ?? 0).toList();
  }
  return null;
}

List<T>? _asList<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
  if (v is List) {
    return v
        .whereType<Map<String, dynamic>>()
        .map((e) => fromJson(e))
        .toList();
  }
  return null;
}

class Client {
  final int id;
  final String? hwaddr; // maps from "client"
  final String? hostname; // maps from "name"
  final String? comment;
  final List<int>? groupIds; // maps from "groups"

  Client({
    required this.id,
    this.hwaddr,
    this.hostname,
    this.comment,
    this.groupIds,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: _asInt(json['id']) ?? 0,
        hwaddr: _asOrNull<String>(json['client']),
        hostname: _asOrNull<String>(json['name']),
        comment: _asOrNull<String>(json['comment']),
        groupIds: _asIntList(json['groups']),
      );
}

class Domain {
  final int id;
  final String? name; // "domain"
  final String? type;
  final String? kind;
  final String? comment;
  final List<int>? groupIds; // "groups"
  final bool enabled;

  Domain({
    required this.id,
    this.name,
    this.type,
    this.kind,
    this.comment,
    this.groupIds,
    required this.enabled,
  });

  factory Domain.fromJson(Map<String, dynamic> json) => Domain(
        id: _asInt(json['id']) ?? 0,
        name: _asOrNull<String>(json['domain']),
        type: _asOrNull<String>(json['type']),
        kind: _asOrNull<String>(json['kind']),
        comment: _asOrNull<String>(json['comment']),
        groupIds: _asIntList(json['groups']),
        enabled: _asBool(json['enabled']) ?? false,
      );
}

class AuthResponse {
  final SessionInfo? session;
  final double took;

  AuthResponse({
    required this.session,
    required this.took,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        session: json['session'] is Map<String, dynamic>
            ? SessionInfo.fromJson(json['session'])
            : null,
        took: _asDouble(json['took']) ?? 0.0,
      );
}

class SessionInfo {
  final bool valid;
  final bool totp;
  final String? sid;
  final String? csrf;
  final int validity;
  final String? message;

  SessionInfo({
    required this.valid,
    required this.totp,
    this.sid,
    this.csrf,
    required this.validity,
    this.message,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
        valid: _asBool(json['valid']) ?? false,
        totp: _asBool(json['totp']) ?? false,
        sid: _asOrNull<String>(json['sid']),
        csrf: _asOrNull<String>(json['csrf']),
        validity: _asInt(json['validity']) ?? 0,
        message: _asOrNull<String>(json['message']),
      );
}

class BlockingStatus {
  static const enabled = 'enabled';
  static const disabled = 'disabled';
}

class BlockingResponse {
  final String? blocking;
  final double? timer;
  final double took;

  BlockingResponse({this.blocking, this.timer, required this.took});

  factory BlockingResponse.fromJson(Map<String, dynamic> json) =>
      BlockingResponse(
        blocking: _asOrNull<String>(json['blocking']),
        timer: _asDouble(json['timer']),
        took: _asDouble(json['took']) ?? 0.0,
      );
}

class ClientsResponse {
  final List<Client>? clients;
  ClientsResponse({this.clients});

  factory ClientsResponse.fromJson(Map<String, dynamic> json) =>
      ClientsResponse(
        clients: _asList<Client>(json['clients'], Client.fromJson),
      );
}

class DomainsResponse {
  final List<Domain>? domains;
  DomainsResponse({this.domains});

  factory DomainsResponse.fromJson(Map<String, dynamic> json) =>
      DomainsResponse(
        domains: _asList<Domain>(json['domains'], Domain.fromJson),
      );
}

class StatusResponse {
  final String? status;
  StatusResponse({this.status});

  factory StatusResponse.fromJson(Map<String, dynamic> json) =>
      StatusResponse(status: _asOrNull<String>(json['status']));
}

class NetworkResponse {
  final List<Network>? networks;
  NetworkResponse({this.networks});

  factory NetworkResponse.fromJson(Map<String, dynamic> json) =>
      NetworkResponse(
        networks: _asList<Network>(json['networks'], Network.fromJson),
      );
}

class Network {
  final int id;
  final String? networkAddress; // "network"
  final String? name;
  final String? comment;
  final List<int>? groupIds; // "group_ids"

  Network({
    required this.id,
    this.networkAddress,
    this.name,
    this.comment,
    this.groupIds,
  });

  factory Network.fromJson(Map<String, dynamic> json) => Network(
        id: _asInt(json['id']) ?? 0,
        networkAddress: _asOrNull<String>(json['network']),
        name: _asOrNull<String>(json['name']),
        comment: _asOrNull<String>(json['comment']),
        groupIds: _asIntList(json['group_ids']),
      );
}

class ClientGroupAssignment {
  final int clientId;
  final String clientIp;
  final int groupId;
  final String groupName;

  ClientGroupAssignment({
    required this.clientId,
    required this.clientIp,
    required this.groupId,
    required this.groupName,
  });

  factory ClientGroupAssignment.fromJson(Map<String, dynamic> json) {
    return ClientGroupAssignment(
      clientId: json['client_id'] as int,
      clientIp: json['client_ip'] as String,
      groupId: json['group_id'] as int,
      groupName: json['group_name'] as String,
    );
  }
}

class ClientGroupsResponse {
  final List<ClientGroupAssignment> clientGroups;

  ClientGroupsResponse({required this.clientGroups});

  factory ClientGroupsResponse.fromJson(Map<String, dynamic> json) {
    return ClientGroupsResponse(
      clientGroups: (json['client_groups'] as List)
          .map((item) => ClientGroupAssignment.fromJson(item))
          .toList(),
    );
  }
}

class ClientGroupsBatchResponse {
  final List<Map<String, dynamic>> success;
  final List<Map<String, dynamic>> errors;

  ClientGroupsBatchResponse({
    required this.success,
    required this.errors,
  });

  factory ClientGroupsBatchResponse.fromJson(Map<String, dynamic> json) {
    final processed = json['processed'] as Map<String, dynamic>;
    return ClientGroupsBatchResponse(
      success: (processed['success'] as List).cast<Map<String, dynamic>>(),
      errors: (processed['errors'] as List).cast<Map<String, dynamic>>(),
    );
  }
}

class GroupsResponse {
  final List<Group>? groups;
  GroupsResponse({this.groups});

  factory GroupsResponse.fromJson(Map<String, dynamic> json) =>
      GroupsResponse(
        groups: _asList<Group>(json['groups'], Group.fromJson),
      );
}

class Group {
  final int id;
  final String name;
  final String description;
  final bool enabled;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.enabled,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: _asInt(json['id']) ?? 0,
        name: _asStringOrEmpty(json['name']),
        description: _asStringOrEmpty(json['description']),
        enabled: _asBool(json['enabled']) ?? false,
      );
}

/// Model for group information matching FTL API response
/// API format: {"group_id": 0, "group_name": "Default"}
/// 
class GroupInfoListResponse {
  final List<GroupInfo>? groupInfos;
  GroupInfoListResponse({this.groupInfos});

  factory GroupInfoListResponse.fromJson(Map<String, dynamic> json) =>
      GroupInfoListResponse(
            groupInfos: _asList<GroupInfo>(json['groupInfos'], GroupInfo.fromJson),
      );
}

class GroupInfo {
  final int id;
  final String name;
  final bool isAssigned;

  GroupInfo({
    required this.id,
    required this.name,
    required this.isAssigned,
  });

  GroupInfo copyWith({bool? isAssigned}) {
    return GroupInfo(
      id: id,
      name: name,
      isAssigned: isAssigned ?? this.isAssigned,
    );
  }

  /// Create from API response JSON
  factory GroupInfo.fromJson(Map<String, dynamic> json, {bool isAssigned = false}) {
    return GroupInfo(
      id: json['group_id'] as int? ?? json['id'] as int,
      name: json['group_name'] as String? ?? json['name'] as String,
      isAssigned: isAssigned,
    );
  }
}

class NetworkDevicesResponse {
  final List<NetworkDevice>? devices;
  NetworkDevicesResponse({this.devices});

  factory NetworkDevicesResponse.fromJson(Map<String, dynamic> json) =>
      NetworkDevicesResponse(
        devices: _asList<NetworkDevice>(json['devices'], NetworkDevice.fromJson),
      );
}

class NetworkDevice {
  final int id;
  final String? hwAddr; // "hwAddr"
  final String? interface;
  final int firstSeen; // epoch seconds?
  final int lastQuery; // epoch seconds?
  final int numQueries;
  final String? macVendor;
  final List<DeviceIp>? ips;

  NetworkDevice({
    required this.id,
    this.hwAddr,
    this.interface,
    required this.firstSeen,
    required this.lastQuery,
    required this.numQueries,
    this.macVendor,
    this.ips,
  });

  factory NetworkDevice.fromJson(Map<String, dynamic> json) => NetworkDevice(
        id: _asInt(json['id']) ?? 0,
        hwAddr: _asOrNull<String>(json['hwaddr']),
        interface: _asOrNull<String>(json['interface']),
        firstSeen: _asInt(json['firstSeen']) ?? 0,
        lastQuery: _asInt(json['lastQuery']) ?? 0,
        numQueries: _asInt(json['numQueries']) ?? 0,
        macVendor: _asOrNull<String>(json['macVendor']),
        ips: _asList<DeviceIp>(json['ips'], DeviceIp.fromJson),
      );
}

class QueriesResponse {
  final List<Query>? queries;
  QueriesResponse({this.queries});

  factory QueriesResponse.fromJson(Map<String, dynamic> json) =>
      QueriesResponse(
        queries: _asList<Query>(json['queries'], Query.fromJson),
      );
}

class Reply {
  final String type; // maps from "Type"
  final double time; // maps from "Time"

  Reply({required this.type, required this.time});

  factory Reply.fromJson(Map<String, dynamic> json) => Reply(
        type: _asOrNull<String>(json['Type']) ?? '',
        time: _asDouble(json['Time']) ?? 0.0,
      );
}

class ClientIP {
  final String ip;
  final String? name;

  ClientIP({required this.ip, this.name});

  factory ClientIP.fromJson(Map<String, dynamic> json) => ClientIP(
        ip: _asOrNull<String>(json['ip']) ?? '',
        name: _asOrNull<String>(json['name']),
      );
}

class EDE {
  final int code;
  final String? text;

  EDE({required this.code, this.text});

  factory EDE.fromJson(Map<String, dynamic> json) => EDE(
        code: _asInt(json['code']) ?? 0,
        text: _asOrNull<String>(json['text']),
      );
}

class Query {
  final int id;
  final double time;
  final String type;
  final String status;
  final String dnsSec; // "dnssec"
  final String? upstream;
  final String domain;
  final Reply reply;
  final ClientIP client;
  final int? listId;
  final EDE ede; // "ede"
  final String? cName;

  Query({
    required this.id,
    required this.time,
    required this.type,
    required this.status,
    required this.dnsSec,
    this.upstream,
    required this.domain,
    required this.reply,
    required this.client,
    this.listId,
    required this.ede,
    this.cName,
  });

  factory Query.fromJson(Map<String, dynamic> json) => Query(
        id: _asInt(json['id']) ?? 0,
        time: _asDouble(json['time']) ?? 0.0,
        type: _asOrNull<String>(json['type']) ?? '',
        status: _asOrNull<String>(json['status']) ?? '',
        dnsSec: _asOrNull<String>(json['dnssec']) ?? '',
        upstream: _asOrNull<String>(json['upstream']),
        domain: _asOrNull<String>(json['domain']) ?? '',
        reply: Reply.fromJson(
            (json['reply'] as Map<String, dynamic>? ?? const {})),
        client: ClientIP.fromJson(
            (json['client'] as Map<String, dynamic>? ?? const {})),
        listId: _asInt(json['list_id']),
        ede: EDE.fromJson((json['ede'] as Map<String, dynamic>? ?? const {})),
        cName: _asOrNull<String>(json['cname']),
      );
}

class DeviceIp {
  final String? ip;
  final String? name;
  final int lastSeen;
  final int nameUpdated;

  DeviceIp({
    this.ip,
    this.name,
    required this.lastSeen,
    required this.nameUpdated,
  });

  factory DeviceIp.fromJson(Map<String, dynamic> json) => DeviceIp(
        ip: _asOrNull<String>(json['ip']),
        name: _asOrNull<String>(json['name']),
        lastSeen: _asInt(json['lastSeen']) ?? 0,
        nameUpdated: _asInt(json['nameUpdated']) ?? 0,
      );
}

// A small helper if you need to decode raw http responses consistently.
Map<String, dynamic> decodeJsonObject(String body) =>
    json.decode(body) as Map<String, dynamic>;