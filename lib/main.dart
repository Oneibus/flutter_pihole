import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'pihole/pihole_service.dart';
import 'pihole/pihole_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Two Panel Master/Detail',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MasterDetailPage(),
    );
  }
}

class MasterDetailPage extends StatefulWidget {
  const MasterDetailPage({super.key});
  @override
  State<MasterDetailPage> createState() => _MasterDetailPageState();
}

class _MasterDetailPageState extends State<MasterDetailPage> {
  static const categories = <String>[
    'Groups',
    'Clients',
    'Domains',
    'Network',
    'Queries',
    'System',
  ];
  String _selected = categories.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_selected)),
      body: Row(
        children: [
          // Left panel
          Container(
            width: 220,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final name = categories[i];
                final selected = _selected == name;
                return ListTile(
                  title: Text(name),
                  selected: selected,
                  selectedTileColor: Theme.of(context).colorScheme.primary,
                  onTap: () => setState(() => _selected = name),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // Right panel
          Expanded(
            child: CategoryListView(category: _selected),
          ),
        ],
      ),
    );
  }
}

class UnusedCategoryListView extends StatelessWidget {
  final String category;
  const UnusedCategoryListView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {

    final futureBuilder = FutureBuilder<List<String>>(key: ValueKey(category), // reset when category changes
                                       future: DataService.fetchItems(category),
                                       builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? const <String>[];
        if (items.isEmpty) {
          return Center(child: Text('No $category found.'));
        }

        return ListView.separated(itemCount: items.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(title: Text(item), onTap: () {
                // Optional: handle item tap
              },
            );
          },
        );

      },
    );

    return futureBuilder;
  }
}

class CategoryListView extends StatelessWidget {
  final String category;
  const CategoryListView({super.key, required this.category});

  Widget _buildItemRow(BuildContext context, String item, int index) {
    // Try to split a primary / secondary line by common separators.
    String primary = item;
    String? secondary;
    String? status;
    
    if (item.contains(' — ')) {
      final parts = item.split(' — ');
      primary = parts.first;
      secondary = parts.length > 1 ? parts[1] : null;
      status = parts.length > 2 ? parts.sublist(2).join(' — ') : null;
    } else if (item.contains(" - ")) {
      final parts = item.split(' - ');
      primary = parts.first;
      secondary = parts.length > 1 ? parts[1] : null;
      status = parts.length > 2 ? parts.sublist(2).join(' - ') : null;
    } else if (item.contains('|')) {
      final parts = item.split('|').map((s) => s.trim()).toList();
      primary = parts.first;
      secondary = parts.length > 1 ? parts[1] : null;
      // status = parts.length > 2 ? parts.sublist(2).join(' | ') : null;
      status = parts.length > 2 ? parts[2].trim() : null;
    } else {
      // try to extract trailing status in parentheses, e.g. "domain (blocked)"
      final m = RegExp(r'^(.*?)(\s+\([^)]+\))$').firstMatch(item);
      if (m != null) {
        primary = m.group(1) ?? item;
        status = (m.group(2) ?? '').trim();
      }
    }

    return InkWell(
      onTap: () {
        // Optional: handle item tap
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: index.isEven ? Colors.grey[50] : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Index/Number column
            SizedBox(
              width: 50,
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Primary content column
            Expanded(
              flex: 3,
              child: Text(
                primary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Secondary content column
            if (secondary != null)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    secondary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // Status column
            if (status != null)
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status.toLowerCase().contains('blocked') 
                          ? Colors.red[100] 
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: status.toLowerCase().contains('blocked') 
                            ? Colors.red[800] 
                            : Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
          const Expanded(
            flex: 3,
            child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text('Status', 
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      key: ValueKey(category), // reset when category changes
      future: DataService.fetchItems(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data ?? const <String>[];
        if (items.isEmpty) {
          return Center(child: Text('No $category found.'));
        }

        // Table-like layout with full rows and columns
        return Column(
          children: [
            // Header row
            _buildHeaderRow(context),
            // Data rows
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildItemRow(context, items[index], index),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DataService {
  // Read from Windows environment variables (fallbacks included)
  static final Map<String, String> _env = (() {
    try {
      return Platform.environment;
    } catch (_) {
      return const <String, String>{};
    }
  })();

  static final String baseUrl = _env['PIHOLE_APP_HOSTURL'] ?? 'http://localhost';
  static final String appPassword = _env['PIHOLE_APP_PASSWORD'] ?? 'generated_app_password';

  static final _service = PiHoleService(
    PiHoleClient(
      baseUrl: '$baseUrl/api',
      appPassword: appPassword,
    ),
  );

  static Future<List<String>> fetchItems(String category) {
    return _service.listForCategory(category);
  }
}
