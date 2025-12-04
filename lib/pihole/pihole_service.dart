// import 'package:flutter_pihole_client/pihole/api_models.dart';

import 'pihole_client.dart';
import 'api_models.dart';

class PiHoleService {
  final PiHoleClient _client;

  PiHoleService(this._client);

  // Convenience: map categories in your UI to calls
  Future<bool> updateCategoryItem(String category, String listitem, {Map<String, Object?>? props}) async {
    final catName = category.toLowerCase();
    switch (catName) {
      case 'groups':
        final res = await _client.putCategoryItem(category: catName, listitem: listitem, props: props ?? {});
        bool saved = res.status == 'success';
        return saved;
      case 'domains':
        // hack: handle enable/disable via 'allow' prop
        props?['type'] = 'deny';
        props?['kind'] = 'exact';
        props?['domain'] = props['name'];
        props?['status'] = props['enabled'] == true ? 'enabled' : 'disabled';

        // props?['enabled'] = props?['enabled'] == true ? false : true;
        String path = '$catName/${props?['type']}/${props?['kind']}';
        final res = await _client.putCategoryItem(category: path, listitem: listitem, props: props ?? {});
        bool saved = res.status == 'success';
        return saved;
    }
    return false;
  }

  // Convenience: map categories in your UI to calls
  Future<List<dynamic>> listForCategory(String category) async {
    switch (category.toLowerCase()) {
      case 'groups':
        final res = await _client.getGroups();
        return res.groups?.map((g) => {
              'primary': g.name,
              'secondary': g.description,
              'status': g.enabled ? 'enabled' : 'disabled',
              'id': g.id,
              'name': g.name,
              'description': g.description,
              'enabled': g.enabled,
            }).toList() ?? [];

      case 'clients':
        final res = await _client.getClients();
        return (res.clients?.map((c) => {
              'primary': c.hostname!.isNotEmpty ? c.hostname : c.hwaddr ?? '',
              'secondary': c.comment ?? '',
              'status': c.groupIds?.map((id) => id.toString()).toList().join(', ') ?? '',
              'id': c.id,
              'name': c.hostname,
              'ip': c.hwaddr,
              'comment': c.comment,
              'groups': c.groupIds,
            }).toList()) ?? [];

      case 'domains':
        final res = await _client.getDomains();
        return (res.domains?.map((d) => {
              'primary': d.name ?? '',
              'secondary': d.comment ?? '',
              'status': d.enabled ? 'enabled' : 'disabled',
              'id': d.id,
              'domain': d.name,
              'type': d.type,
              'kind': d.kind,
              'comment': d.comment,
              'enabled': d.enabled,
            }).toList()) ?? [];

      case 'network':
        final res = await _client.getNetworkDevices();
        return (res.devices?.map((n) => {
               if (n.ips!.isEmpty) ...{
                 'primary': n.macVendor ?? n.hwAddr ?? 'unknown',
                 'secondary': n.hwAddr ?? n.interface ?? 'unknown',
                 'ip': '(stale)',
                 'name': '${n.macVendor ?? n.hwAddr ?? 'unknown'})',
               } else ...{
                'primary': n.ips![0].name ?? '',
                'secondary': n.ips![0].ip ?? '',
                'ip': n.ips![0].ip ?? '',
                'name': n.ips![0].name,
               },
              'status': n.numQueries.toString(),
              'id': n.id,
              'hwaddr': n.hwAddr ?? '',
              'interface': n.interface,
              'queries': n.numQueries,
            }).toList()) ?? [];

      case 'queries':
        final res = await _client.getQueries();
        return (res.queries?.map((q) => {
              'primary': q.domain,
              'secondary': q.client.name ?? q.client.ip,
              'status': q.status,
              'id': q.id,
              'client': q.client.name ?? '',
              'domain': q.domain,
              'timestamp': q.time,
            }).toList()) ?? [];

     case 'system':
     default:
        return [];
    }
  }

  Future<List<GroupInfo>> getGroupsForClient(int clientId) async {
    return await _client.getGroupsForClient(clientId);
  }
  
  Future<bool> updateClientGroups(int clientId, List<int> groupIds) async {
    return await _client.updateClientGroups(clientId, groupIds);
  }

  static Future<bool> updateItem(String category, String name, {Map<String, Object?>? props}) async {
    // Implementation would be in main.dart
    throw UnimplementedError();
  }

  Future<bool> restartDNS() async => _client.restartDNS();

  Future<bool> flushNetworkCache() async => _client.flushNetworkCache();

  Future<bool> rebootSystem() async => _client.rebootSystem();

  Future<bool> enableBlocking() async => _client.enableBlocking();

  Future<bool> disableBlocking({int? duration}) async => _client.disableBlocking(duration: duration);

  Future<Map<String, dynamic>> getBlockingStatus() async => _client.getBlockingStatus();

  Future<bool> isBlockingEnabled() async {
    final status = await _client.getBlockingStatus();
    return status['blocking'] == 'enabled';
  }

  Future<bool> isConfigured() async {
    final bool? status = await _client.getConfigurationStatus();
    return status!;
  }

  Future<void> resetService() async {
    _client.resetService();
  }

  Future<void> logout() async {
    _client.resetService();
  }
}