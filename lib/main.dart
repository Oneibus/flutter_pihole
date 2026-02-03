// import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pihole_client/services/settings_service.dart';

import 'services/system_events.dart';
import 'services/data_services.dart';
import 'services/service_locator.dart';
import 'widgets/edit_item_dialog.dart';
import 'widgets/edit_client_groups_dialog.dart';
import 'widgets/sortable_header.dart';
import 'widgets/collapsible_panel.dart';

void main() {
  // Setup dependency injection before running app
  setupServiceLocator();
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

class _MasterDetailPageState extends State<MasterDetailPage>
    with WidgetsBindingObserver {
  SettingsService get settingsService => getIt<SettingsService>();

  static const categories = <String>[
    'Groups',
    'Clients',
    'Domains',
    'Network',
    'Queries',
    'System',
  ];

  static String _selectedCategory = categories.first;
  int _refreshKey = 0; // Key to force refresh
  bool _isRebooting = false; // Track reboot state
  String? _piholeHost = '';

  // Key to control the collapsible panel
  final GlobalKey<CollapsiblePanelState> _panelKey =
      GlobalKey<CollapsiblePanelState>();

  // Auto-collapse timer
  Timer? _autoCollapseTimer;
  static const Duration _autoCollapseDelay = Duration(seconds: 3);
  bool _isHoveringLeftPanel = false;
  bool _hasPendingCollapse = false;

  // Key to measure right panel layout
  final GlobalKey _rightPanelKey = GlobalKey();

  // Track window size for resize/rotation detection
  Size? _previousSize;
  Timer? _resizeDebounceTimer;

  StreamSubscription<RebootEvent>? _rebootSubscription;
  StreamSubscription<ServiceReadinessEvent>? _serviceSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _resizeDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    dataService.systemEvents.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // The engine is shutting down (User swiped away the app or OS killed it)
      // Note: Network calls here are "best effort" and may not always complete
      // on mobile OSs due to strict background limits, but it helps.
      dataService.logout();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Get current size
    final currentSize = MediaQuery.of(context).size;

    // Check if size actually changed (orientation or window resize)
    if (_previousSize != null &&
        (_previousSize!.width != currentSize.width ||
            _previousSize!.height != currentSize.height)) {
      // Cancel any pending collapse
      _autoCollapseTimer?.cancel();
      _hasPendingCollapse = false;

      // Expand panel immediately
      _panelKey.currentState?.expand();

      // Debounce: wait for resize/rotation to complete before starting timer
      _resizeDebounceTimer?.cancel();
      _resizeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Start auto-collapse timer if not hovering
          if (!_isHoveringLeftPanel) {
            _startAutoCollapseTimer();
          } else {
            _hasPendingCollapse = true;
          }
        }
      });
    }

    _previousSize = currentSize;
  }

  /// Start auto-collapse timer after category selection
  void _startAutoCollapseTimer() {
    // Cancel any existing timer
    _autoCollapseTimer?.cancel();

    // If hovering over left panel, mark as pending and wait
    if (_isHoveringLeftPanel) {
      _hasPendingCollapse = true;
      return;
    }

    // Start new timer
    _autoCollapseTimer = Timer(_autoCollapseDelay, () {
      if (!mounted) return;

      // Check if content needs more space before collapsing
      if (_shouldAutoCollapse()) {
        _panelKey.currentState?.collapse();
      }
    });
  }

  /// Check if the panel should auto-collapse based on available space
  bool _shouldAutoCollapse() {
    // Always collapse on narrow screens (phones in portrait)
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return true;
    }

    // For larger screens, check if we have enough space
    // If right panel has plenty of room, don't collapse
    if (screenWidth > 1200) {
      return false;
    }

    // For medium screens, collapse to give more room
    return true;
  }

  // Initialize application and load initial DNS blocking status
  Future<void> _initializeApp() async {
    try {
      // Load hostname from settings
      final hostname = await dataService.hostName;
      if (mounted) {
        setState(() {
          _piholeHost = hostname;
        });
      }
      await _setupEventListeners();
    } catch (e) {
      // Silently handle initialization errors
      debugPrint('Failed to initialize blocking status: $e');
    }
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
          // Left panel - now collapsible
          MouseRegion(
            onEnter: (_) {
              setState(() {
                _isHoveringLeftPanel = true;
              });
            },
            onExit: (_) {
              setState(() {
                _isHoveringLeftPanel = false;
              });
              // If there's a pending collapse, start the timer now
              if (_hasPendingCollapse) {
                _hasPendingCollapse = false;
                _startAutoCollapseTimer();
              }
            },
            child: CollapsiblePanel(
              key: _panelKey,
              expandedWidth: 100,
              collapsedWidth: 8,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                    top: 8.0, bottom: 4.0, left: 8.0, right: 0.0),
                itemCount: categories.length,
                itemBuilder: (ctx, i) {
                  final name = categories[i];
                  final selected = _selectedCategory == name;

                  // Use InkWell + Container instead of ListTile for narrow columns
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: _isRebooting
                            ? null
                            : () {
                                setState(() {
                                  _selectedCategory = name;
                                });
                                // Start auto-collapse timer after selection
                                _startAutoCollapseTimer();
                              },
                        child: Container(
                          height: 48, // Fixed comfortable height
                          alignment: Alignment
                              .centerLeft, // Ensure text starts at left
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0), // Manual padding
                          color: selected
                              ? Colors.green[200]
                              : Theme.of(context)
                                  .colorScheme
                                  .surface, // Selection background
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: selected ? 14 : 12,
                              // Use onSurface so it adapts to Dark/Light mode automatically
                              color: selected
                                  ? Colors.green[900]
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const VerticalDivider(width: 2),
          // Right panel with rounded corners and matching background
          Expanded(
            key: _rightPanelKey,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CategoryListView(
                    key: ValueKey(
                        '$_selectedCategory-$_refreshKey'), // Force rebuild when key changes
                    category: _selectedCategory,
                    isRebooting: _isRebooting,
                    onItemUpdate: (category, initialName, props) async {
                      if (props['delete'] == true) {
                        await dataService.deleteItem(category, initialName,
                            props: props);
                      } else {
                        await dataService.updateItem(category, initialName,
                            props: props);
                      }
                      // Trigger refresh after update
                      setState(() {
                        _refreshKey++;
                      });
                    },
                    onRefresh: () {
                      setState(() {
                        _refreshKey++;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: NavigationToolbar(
            middle: Text(
              _isRebooting
                  ? 'Connection pending...'
                  : 'Connected to: ${_piholeHost ?? 'Unknown'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  // Setup listeners for system events and show SnackBars accordingly
  Future<void> _setupEventListeners() async {
    await dataService.initializeBlockingStatus();
    // Listen to reboot events

    _rebootSubscription = dataService.systemEvents.rebootStream.listen((event) {
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
    _serviceSubscription =
        dataService.systemEvents.serviceStream.listen((event) {
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
          setState(() {
            _piholeHost = event.host;
            _refreshKey++;
          });
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
}

typedef ItemUpdateCallback = Future<void> Function(
    String category, String name, Map<String, Object?> props);
typedef RefreshCallback = void Function();

class CategoryListView extends StatefulWidget {
  final String category;
  final String? param1;
  final String? param2;
  final bool isRebooting;
  final ItemUpdateCallback? onItemUpdate;
  final RefreshCallback? onRefresh;

  const CategoryListView({
    super.key,
    required this.category,
    required this.isRebooting,
    this.onItemUpdate,
    this.onRefresh,
    this.param1,
    this.param2,
  });

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  // Sorting and filtering state
  String? _sortColumn;
  SortOrder _sortOrder = SortOrder.none;
  final Map<String, String> _columnFilters = {};
  List<dynamic> _filteredAndSortedItems = [];

  // Cache for original items from API
  List<dynamic>? _cachedItems;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await dataService.fetchItems(widget.category,
          param1: widget.param1, param2: widget.param2);
      // Add original index to each item for display purposes
      final itemsWithIndex = items.asMap().entries.map((entry) {
        final item = Map<String, dynamic>.from(entry.value);
        item['_originalIndex'] = entry.key + 1; // Store 1-based index
        return item;
      }).toList();

      setState(() {
        _cachedItems = itemsWithIndex;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        // When clicking on an already sorted column, just toggle between ascending/descending
        // Note: This is called when clicking the dropdown menu
        // Direct icon clicks will use a different path
        switch (_sortOrder) {
          case SortOrder.none:
            _sortOrder = SortOrder.ascending;
            break;
          case SortOrder.ascending:
            _sortOrder = SortOrder.descending;
            break;
          case SortOrder.descending:
            _sortOrder = SortOrder.none;
            _sortColumn = null;
            break;
        }
      } else {
        _sortColumn = column;
        _sortOrder = SortOrder.ascending;
      }
    });
  }

  void _toggleSortDirect(String column) {
    setState(() {
      // Direct toggle only switches between ascending/descending, never to none
      if (_sortColumn == column) {
        _sortOrder = _sortOrder == SortOrder.ascending
            ? SortOrder.descending
            : SortOrder.ascending;
      } else {
        // If clicking on a different column's sort icon, start with ascending
        _sortColumn = column;
        _sortOrder = SortOrder.ascending;
      }
    });
  }

  void _setFilter(String column, String filterText) {
    setState(() {
      if (filterText.isEmpty) {
        _columnFilters.remove(column);
      } else {
        _columnFilters[column] = filterText;
      }
    });
  }

  List<dynamic> _applyFiltersAndSort(List<dynamic> items) {
    var result = List<dynamic>.from(items);

    // Apply filters
    for (var entry in _columnFilters.entries) {
      final column = entry.key;
      final filter = entry.value.toLowerCase();

      result = result.where((item) {
        final value = item[column]?.toString().toLowerCase() ?? '';
        return value.startsWith(filter);
      }).toList();
    }

    // Apply sorting
    if (_sortColumn != null && _sortOrder != SortOrder.none) {
      result.sort((a, b) {
        final aValue = a[_sortColumn]?.toString() ?? '';
        final bValue = b[_sortColumn]?.toString() ?? '';

        final comparison = aValue.compareTo(bValue);
        return _sortOrder == SortOrder.ascending ? comparison : -comparison;
      });
    }

    return result;
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 128, 0, 0),
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
      child: Row(
        children: [
          // item number - not sortable
          const SizedBox(
            width: 30,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '#',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // primary column - sortable and filterable
          SortableHeaderCell(
            label: 'Name',
            isExpanded: true,
            flex: 3,
            sortOrder: _sortColumn == 'primary' ? _sortOrder : SortOrder.none,
            filterText: _columnFilters['primary'],
            onSort: () => _toggleSort('primary'),
            onSortDirect: () => _toggleSortDirect('primary'),
            onFilterChanged: (text) => _setFilter('primary', text),
          ),

          // secondary column - sortable and filterable
          SortableHeaderCell(
            label: 'Details',
            isExpanded: true,
            flex: 3,
            sortOrder: _sortColumn == 'secondary' ? _sortOrder : SortOrder.none,
            filterText: _columnFilters['secondary'],
            onSort: () => _toggleSort('secondary'),
            onSortDirect: () => _toggleSortDirect('secondary'),
            onFilterChanged: (text) => _setFilter('secondary', text),
          ),

          // status column - sortable and filterable
          SortableHeaderCell(
            label: 'Status',
            width: 100,
            sortOrder: _sortColumn == 'status' ? _sortOrder : SortOrder.none,
            filterText: _columnFilters['status'],
            onSort: () => _toggleSort('status'),
            onSortDirect: () => _toggleSortDirect('status'),
            onFilterChanged: (text) => _setFilter('status', text),
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
    String? type = item['type'];
    String? kind = item['kind'];
    bool redlined = item['redline'] == true;

    return InkWell(
      onTap: (mounted && widget.onItemUpdate != null && !widget.isRebooting)
          ? () async {
              if (widget.category.toLowerCase() == 'clients') {
                // Parse client ID from primary (assuming it's the first part)
                final groups = await dataService.getGroupsForClient(id);

                await EditClientGroupsDialog.show(
                  context: context,
                  category: widget.category,
                  clientId: id,
                  clientName: primary ?? '',
                  availableGroups: groups,
                  onUpdate: (clientId, groupIds) async {
                    await dataService.updateClientGroups(clientId, groupIds);
                  },
                );
                return;
              }

              // Create controllers that will be managed by the dialog
              final nameController = TextEditingController(text: primary ?? '');
              final commentController =
                  TextEditingController(text: secondary ?? '');
              String currentStatus = status ?? 'disabled';
              String currentType = type ?? 'unknown';
              String currentKind = kind ?? 'unknown';

              await DynamicItemEditDialog.show(
                  context,
                  Icons.edit,
                  widget.category,
                  editItemDialogContent(
                    context,
                    widget.category,
                    nameController,
                    commentController,
                    currentStatus,
                    (String value) => primary = value,
                    (String value) => secondary = value,
                    (String? value) => currentStatus = value ?? currentStatus,
                    (String? value) => currentType = value ?? currentType,
                    (String? value) => currentKind = value ?? currentKind,
                  ), () async {
                // Save callback
                if (mounted && widget.onItemUpdate != null) {
                  await widget.onItemUpdate!(
                    widget.category,
                    primary ?? '',
                    {
                      // RFJ: refactor to use property names per category
                      'name': nameController.text,
                      'comment': commentController.text.isEmpty
                          ? null
                          : commentController.text,
                      'enabled': currentStatus == 'enabled',
                      'delete': currentStatus == 'delete',
                      'type': currentType,
                      'kind': currentKind,
                    },
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
                // Dispose controllers after save
                nameController.dispose();
                commentController.dispose();
              }, () {
                // Cancel callback
                if (mounted) {
                  Navigator.of(context).pop();
                }
                // Dispose controllers after cancel
                nameController.dispose();
                commentController.dispose();
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: BoxDecoration(
          color: (redlined == true)
              ? Colors.red[100]
              : (index.isEven ? Colors.lightGreen[50] : Colors.white),
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
                  '${item['_originalIndex'] ?? (index + 1)}',
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
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: redlined == true
                                ? Colors.red[900]
                                : Colors.green[800],
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                      textAlign: TextAlign.left,
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
    // Handle loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    // Handle special System category
    if (widget.category == 'System') {
      return dataService.buildSystemDialog(context: context);
    }

    // Handle empty data
    final items = _cachedItems ?? [];
    if (items.isEmpty) {
      return Center(child: Text('No ${widget.category} found.'));
    }

    // Apply filters and sorting to cached data
    _filteredAndSortedItems = _applyFiltersAndSort(items);

    return Stack(
      children: [
        Column(
          children: [
            // Header row
            _buildHeaderRow(context),
            // Data rows
            Expanded(
              child: Container(
                color: Colors.white, // Background color for the list area
                child: _filteredAndSortedItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_alt_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items match the current filters',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          // Re-fetch from API
                          await _fetchItems();
                          // Call parent's refresh callback if provided
                          if (widget.onRefresh != null) {
                            widget.onRefresh!();
                          }
                        },
                        child: ListView.builder(
                          itemCount: _filteredAndSortedItems.length,
                          itemBuilder: (context, index) => _buildItemRow(
                              context, _filteredAndSortedItems[index], index),
                        ),
                      ),
              ),
            ),
          ],
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
