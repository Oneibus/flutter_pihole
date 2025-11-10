import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'pihole/pihole_service.dart';
import 'pihole/pihole_client.dart';
import 'widgets/edit_item_dialog.dart';

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
  static String _selected = categories.first;
  int _refreshKey = 0; // Key to force refresh

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/PiHoleControl.png',
              height: 56,
              width: 185,
            ),
            // const SizedBox(width: 8),
            // const Text("PiHole Control!"),
          ],
        ),
        titleSpacing: 0,
        backgroundColor: const Color(0xFF222222),
      ),

      body: Row(
        children: [
          // Left panel
          Container(
            width: 200,
            // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final name = categories[i];
                final selected = _selected == name;

                return SizedBox(
                  height: 40, // Fixed height of 40 pixels
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontSize: 12, color: Colors.black)),
                    selected: selected,
                    selectedTileColor: Theme.of(context).colorScheme.surfaceBright,
                    onTap: () => setState(() => _selected = name),
                  ),
                );
              },
            ),
          ),
          const VerticalDivider(width: 2),
          // Right panel
          Expanded(
            child: CategoryListView(
              key: ValueKey('$_selected-$_refreshKey'), // Force rebuild when key changes
              category: _selected,
              onItemUpdate: (category, initialName, props) async {
                await DataService.updateItem(category, initialName, props: props);
                // Trigger refresh after update
                setState(() {
                  _refreshKey++;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: NavigationToolbar(
            middle: Text('Connected to: ${DataService.baseUrl}'),
          ),
        ),
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

        return ListView.separated(itemCount: items.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(title: Text(item, style: const TextStyle(fontSize: 10)), onTap: () {
              // Optional: handle item tap
              });
          },
        );
      },
    );

    return futureBuilder;
  }
}

class CategoryListView extends StatelessWidget {
  final String category;
  final ItemUpdateCallback? onItemUpdate;
  
  const CategoryListView({
    super.key, 
    required this.category,
    this.onItemUpdate,
  });

  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 128, 0, 0),
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
      ),

      child: Row(
        children: [
          const SizedBox(width: 40, 
            child: Text('#', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),

          const Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(left: 0),
              child: Text('Name', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.left,
              ),
            ),
          ),

          const Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(left: 0),
              child: Text('Details', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.left,
              ),
            ),
          ),

          const SizedBox(width: 60, 
            child: Padding(
              padding: EdgeInsets.only(left: 0),
              child: Text('Status', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      onTap: onItemUpdate != null ? () async {
        await EditItemDialog.show(
          context: context,
          category: category,
          initialName: primary,
          initialComment: secondary,
          initialStatus: status,
          onUpdate: onItemUpdate!,
        );
      } : null,

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: BoxDecoration(
          color: index.isEven ? Colors.lightGreen[50] : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
        ),

        child: Row(
          children: [
            // Index/Number column
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green[900],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            // Primary content column
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Text(
                  primary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // Secondary content column
            if (secondary != null)
              Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Text(
                  secondary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Status column
            if (status != null)
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status.contains('disabled') 
                          ? Colors.red[110] 
                          : Colors.green[110],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: status.contains('disabled') 
                            ? Colors.red[800] 
                            : Colors.green[800],
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
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

  static final String baseUrl = _env['PIHOLE_APP_HOSTURL'] ?? 'http://pidns.lan';
  static final String appPassword = _env['PIHOLE_APP_PASSWORD'] ?? '5OAsXwzdYFj1X2gweVzV9vtayAVWoF1AwSKvBhJx/2w=';

  static final _service = PiHoleService(
    PiHoleClient(
      baseUrl: '$baseUrl/api',
      appPassword: appPassword,
    ),
  );

  static Future<List<String>> fetchItems(String category) {
    return _service.listForCategory(category);
  }

  static Future<bool> updateItem(String category, String itemName,{Map<String, Object?>? props}) {
    return _service.updateCategoryItem(category, itemName, props: props);
  }
}
