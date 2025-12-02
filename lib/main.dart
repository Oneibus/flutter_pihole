import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'pihole/api_models.dart';
import 'pihole/pihole_service.dart';
import 'pihole/pihole_client.dart';
import 'pihole/system_events.dart';
import 'widgets/edit_item_dialog.dart';
import 'widgets/edit_client_groups_dialog.dart';
import 'widgets/system_dialog.dart';

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
  bool _isRebooting = false; // Track reboot state

  StreamSubscription<RebootEvent>? _rebootSubscription;
  StreamSubscription<ServiceReadinessEvent>? _serviceSubscription;

  @override
  void initState() {
    super.initState();
    _setupEventListeners();
    _initializeApp();
  }

  // Initialize application and load initial DNS blocking status
  Future<void> _initializeApp() async {
    try {
      await DataService.initializeBlockingStatus();
    } catch (e) {
      // Silently handle initialization errors
      debugPrint('Failed to initialize blocking status: $e');
    }
  }

  // Setup listeners for system events and show SnackBars accordingly
  //
  void _setupEventListeners() {
    // Listen to reboot events
    _rebootSubscription = DataService.systemEvents.rebootStream.listen((event) {
      if (!mounted) return;

      String message;
      Color backgroundColor;

      switch (event.state) {
        case RebootState.started:
          message = event.message ?? 'Starting system reboot...';
          backgroundColor = Colors.orange;
          setState(() {
            _isRebooting = true;
          });
          break;
        case RebootState.pending:
          message = event.message ?? 'System is rebooting...';
          backgroundColor = Colors.orange;
          setState(() {
            _isRebooting = true;
          });
          break;
        case RebootState.complete:
          message = event.message ?? 'Reboot completed successfully';
          backgroundColor = Colors.green;
          // Trigger a refresh when reboot completes
          setState(() {
            _isRebooting = false;
            _refreshKey++;
          });
          break;
        case RebootState.failed:
          message = event.message ?? 'Reboot failed';
          backgroundColor = Colors.red;
          setState(() {
            _isRebooting = false;
          });
          break;
        case RebootState.idle:
          setState(() {
            _isRebooting = false;
          });
          return; // Don't show snackbar for idle state
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: event.state == RebootState.pending 
              ? const Duration(seconds: 5) 
              : const Duration(seconds: 3),
        ),
      );
    });

    // Listen to service readiness events
    _serviceSubscription = DataService.systemEvents.serviceStream.listen((event) {
      if (!mounted) return;

      String message;
      Color backgroundColor;

      switch (event.state) {
        case ServiceState.checking:
          message = event.message ?? 'Checking service status...';
          backgroundColor = Colors.blue;
          break;
        case ServiceState.ready:
          message = event.message ?? 'Service is ready';
          backgroundColor = Colors.green;
          break;
        case ServiceState.unavailable:
          message = event.message ?? 'Service unavailable';
          backgroundColor = Colors.red;
          break;
        case ServiceState.unknown:
          return; // Don't show snackbar for unknown state
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  void dispose() {
    _rebootSubscription?.cancel();
    _serviceSubscription?.cancel();
    super.dispose();
  }

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
          ],
        ),
        titleSpacing: 0,
        backgroundColor: const Color(0xFF222222),
      ),

      body: Row(
        children: [
          // Left panel
          Container(
            width: 160,
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
                    title: Text(
                      name, 
                      style: TextStyle(
                        fontSize: selected ? 14 : 12,
                        color: selected ? Colors.green[900] : Colors.black,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: Colors.green[200],
                    enabled: !_isRebooting, // Disable during reboot
                    onTap: _isRebooting ? null : () {
                      setState(() {
                        _selected = name;
                      });
                    },
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
              isRebooting: _isRebooting,
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
        height: 48,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: NavigationToolbar(
            middle: Text(_isRebooting ? 'Connection pending...' : 'Connected to: ${DataService.baseUrl}'),
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

    final futureBuilder = FutureBuilder<List<dynamic>>(key: ValueKey(category), // reset when category changes
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
            return ListTile(title: Text(item, style: const TextStyle(fontSize: 10)), 
              onTap: () {
              // Optional: handle item tap
              });
          },
        );
      },
    );

    return futureBuilder;
  }
}

typedef ItemUpdateCallback = Future<void> Function(String category, String name, Map<String, Object?> props);

class CategoryListView extends StatefulWidget {
  final String category;
  final bool isRebooting;
  final ItemUpdateCallback? onItemUpdate;
  
  const CategoryListView({
    super.key, 
    required this.category,
    required this.isRebooting,
    this.onItemUpdate,
  });

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  // Reboot state is now managed by parent and passed via widget.isRebooting

  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 128, 0, 0),
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
      ),

      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
      child: Row( 
        children: [
          // item number
          const SizedBox(width: 30, 
            child: Text('#', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),

          // primary column
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

          // secondary column
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

          // status column
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

  Widget _buildItemRow(BuildContext context, dynamic item, int index) {
    // Try to split a primary / secondary line by common separators.
    int id = item['id'];
    String? primary = item['primary'];
    String? secondary = item['secondary'];
    String? status = item['status'];

    return InkWell(

      onTap: (mounted && widget.onItemUpdate != null && !widget.isRebooting) ? () async {
        if (widget.category.toLowerCase() == 'clients') {
          // Parse client ID from primary (assuming it's the first part)
          final groups = await DataService.getGroupsForClient(id);

          await EditClientGroupsDialog.show(
            context: context,
            category: widget.category,
            clientId: id,
            clientName: primary ?? '',
            availableGroups: groups,
            onUpdate: (clientId, groupIds) async {
              await DataService.updateClientGroups(clientId, groupIds);
            },
          );
          return;
        }

        // Create controllers that will be managed by the dialog
        final nameController = TextEditingController(text: primary ?? '');
        final commentController = TextEditingController(text: secondary ?? '');
        String currentStatus = status ?? 'disabled';

        await DynamicItemEditDialog.show(
          context, 
          Icons.edit, 
          widget.category, 
          editItemDialogContent(
            nameController,
            commentController,
            currentStatus,
            (String value) => primary = value,
            (String value) => secondary = value,
            (String? value) => currentStatus = value ?? currentStatus
          ), 
          () async {
            // Save callback
            if (mounted && widget.onItemUpdate != null) {
              await widget.onItemUpdate!(
                widget.category, 
                primary ?? '', 
                {
                  // RFJ: refactor to use property names per category
                  'name': nameController.text,
                  'comment': commentController.text.isEmpty ? null : commentController.text,
                  'enabled': currentStatus == 'enabled',
                },
              );
              if (mounted) {
                Navigator.of(context).pop();
              }
            }
            // Dispose controllers after save
            nameController.dispose();
            commentController.dispose();
          },  
          () {
            // Cancel callback
            if (mounted) {
              Navigator.of(context).pop();
            }
            // Dispose controllers after cancel
            nameController.dispose();
            commentController.dispose();
          }
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
              width: 30,
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
                  primary ?? '',
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
                  secondary ?? '',
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
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: status!.contains('disabled') 
                          ? Colors.red[110] 
                          : Colors.green[110],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: status!.contains('disabled')
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
    return Stack(
      children: [
        FutureBuilder<List<dynamic>>(
          key: ValueKey(widget.category), // reset when category changes
          future: DataService.fetchItems(widget.category),
          builder: (context, snapshot) {
            while (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
                // return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }
            // if (snapshot.hasError){
            //   return Center(child: Text('Error: ${snapshot.error}'));
            // }

            final items = snapshot.data ?? const <String>[];
            if (widget.category == 'System') {
              return DataService.buildSystemDialog(context: context);  
            } else if (items.isEmpty) {
              return Center(child: Text('No ${widget.category} found.'));
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
        ),

        // Overlay circular progress indicator when rebooting
        if (widget.isRebooting)
          Container(
            color: Colors.grey[800], // .withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.deepOrange,
                    strokeWidth: 6,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'System is rebooting...',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while the system restarts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.deepOrange[200],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
  static final String sysAccount = _env['PIHOLE_SYS_ACCOUNT'] ?? 'manually set for PiHole admin user name';
  static final String sysPassword = _env['PIHOLE_SYS_PASSWORD'] ?? 'manually set sys_password for PiHole admin user';

  // System event service instance
  static final SystemEventService systemEvents = SystemEventService();

  static final _service = PiHoleService(
    PiHoleClient(
      // baseUrl: '$baseUrl/api',
      hostname: Uri.parse(baseUrl).host,
      sysAdminAccount: sysAccount,
      appPassword: appPassword,
      sysPassword: sysPassword,
      systemEventService: systemEvents,
    ),
  );

  static Future<List<dynamic>> fetchItems(String category) {
    return _service.listForCategory(category);
  }

  static Future<bool> updateItem(String category, String itemName,{Map<String, Object?>? props}) {
    return _service.updateCategoryItem(category, itemName, props: props);
  }

  static Widget buildSystemDialog({required BuildContext context}) {
    return SystemDialog(
      onFlushNetworkTable: _service.flushNetworkTable,
      onRestartDNS: _service.restartDNS,
      onRebootSystem: _service.rebootSystem,
      onEnableBlocking: ({int? duration}) => _service.enableBlocking(),
      onDisableBlocking: ({int? duration}) => _service.disableBlocking(duration: duration),
      onGetBlockingStatus: _service.isBlockingEnabled,
   );
  }

  static Future<List<GroupInfo>> getGroupsForClient(int clientId) {
    return _service.getGroupsForClient(clientId);
  }
  
  static Future<bool> updateClientGroups(int clientId, List<int> groupIds) {
    return _service.updateClientGroups(clientId, groupIds);
  }

  // Initialize and cache the DNS blocking status on app startup
  static Future<void> initializeBlockingStatus() async {
    try {
      // Query the blocking status to initialize/cache it
      await _service.isBlockingEnabled();
    } catch (e) {
      debugPrint('Error initializing blocking status: $e');
      rethrow;
    }
  }
}
