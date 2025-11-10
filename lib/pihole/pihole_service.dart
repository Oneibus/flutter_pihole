import 'package:flutter_pihole_client/pihole/api_models.dart';

import 'pihole_client.dart';

class PiHoleService {
  final PiHoleClient client;

  PiHoleService(this.client);

  // Convenience: map categories in your UI to calls
  Future<bool> updateCategoryItem(String category, String group, {Map<String, Object?>? props}) async {
    final catName = category.toLowerCase();
    switch (catName) {
      case 'groups':
        final res = await client.putCategoryItem(category: catName, group: group, props: props ?? {});
        bool saved = res.status == 'success';
        return saved;
      case 'domains':
        final res = await client.putCategoryItem(category: catName, group: group, props: props ?? {});
        bool saved = res.status == 'success';
        return saved;
    }
    return false;
  }

  // Convenience: map categories in your UI to calls
  Future<List<String>> listForCategory(String category) async {
    switch (category.toLowerCase()) {
      case 'groups':
        final res = await client.getGroups();
        return (res.groups ?? [])
            .map((g) => '${g.name ?? '(unnamed)'}'
                '|${g.description ?? ''}'
                '|${g.enabled ? '(enabled)' : '(disabled)'}')
            .toList();
      case 'clients':
        final res = await client.getClients();
        return (res.clients ?? [])
            .map((c) => '${c.hostname ?? c.hwaddr ?? 'unknown'}'
                '|${c.comment ?? ''}|'
                '')
            .toList();
      case 'domains':
        final res = await client.getDomains();
        return (res.domains ?? [])
            .map((d) => '${d.name?.replaceAll(r"|", "I").toString() ?? '(unknown)'}'
                // '${d.comment ?? '|'} ${d.comment != null ? '|' : ''}'
                '|[${d.kind ?? d.type ?? ''}] ${d.comment ?? ''}'
                '|${d.enabled ? '(enabled)' : '(disabled)'}')
            .toList();
      case 'network':
        final res = await client.getNetworkDevices();
        return (res.devices ?? [])
            .map((n) => '${n.ips?[0].name ?? n.ips?[0].ip ?? n.hwAddr ?? 'network'}'
                '|${n.interface != null ? '${n.numQueries}' : ''}|')
            .toList();
      case 'queries':
        final res = await client.getQueries();
        return (res.queries ?? [])
            .map((q) => '${q.domain}'
                '|${q.client.name ?? ''}'
                '|${q.status ?? ''}')
            .toList();

      case 'system':
      default:
        return [];
    }
  }
}