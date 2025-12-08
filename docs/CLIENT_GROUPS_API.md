# Client Groups API Integration Guide

## Overview

This guide documents the integration between the Flutter app and the Pi-hole FTL `/api/client_groups` endpoints for managing client-to-group assignments.

## Files Created

1. **`lib/widgets/edit_client_groups_dialog.dart`**
   - Dialog widget with checkable list of groups
   - Displays all available groups with checkbox selection
   - Shows current assignment status
   - Handles save/cancel operations

2. **`lib/pihole/client_groups_api_integration.dart`**
   - Complete API integration examples
   - Request/response models
   - Helper methods for PiHoleClient
   - Usage examples

## FTL API Endpoints

Based on `FTL_JCN/client_groups.c`:

### GET /api/client_groups
Get all client-group assignments.

**Response:**
```json
{
  "client_groups": [
    {
      "client_id": 1,
      "client_ip": "192.168.1.100",
      "group_id": 0,
      "group_name": "Default"
    }
  ]
}
```

### GET /api/client_groups/{client_id}
Get groups for a specific client.

**Response:** Same format as above, filtered for client_id

### POST /api/client_groups
Add new client-group assignment(s).

**Single assignment:**
```json
{
  "client_id": 1,
  "group_id": 2
}
```

**Batch mode:**
```json
{
  "assignments": [
    {"client_id": 1, "group_id": 2},
    {"client_id": 1, "group_id": 3}
  ]
}
```

**Response:**
```json
{
  "processed": {
    "success": [
      {"client_id": 1, "group_id": 2}
    ],
    "errors": []
  }
}
```

### PUT /api/client_groups/{client_id}
Update groups for a specific client (batch mode with client_id in URI).

**Payload:**
```json
{
  "assignments": [
    {"group_id": 2},
    {"group_id": 3}
  ]
}
```

### DELETE /api/client_groups/{client_id}/{group_id}
Delete a specific client-group assignment.

**Response:**
```json
{
  "deleted": 1
}
```

### POST /api/client_groups:batchDelete
Delete multiple assignments.

**Payload:**
```json
[
  {"client_id": 1, "group_id": 2},
  {"client_id": 1, "group_id": 3}
]
```

**Response:**
```json
{
  "deleted": 2
}
```

## HTTP Response Codes

- **200 OK** - Successful GET/PUT
- **201 Created** - Successful POST
- **204 No Content** - Successful DELETE (items deleted)
- **400 Bad Request** - Invalid parameters or database error
- **404 Not Found** - DELETE found no items to delete
- **405 Method Not Allowed** - Invalid HTTP method

## Integration Steps

### Step 1: Add Response Models to `api_models.dart`

```dart
```

### Step 2: Add Methods to `PiHoleClient`

```dart
```

### Step 3: Add to `DataService` in `main.dart`

```dart
```

### Step 4: Update `CategoryListView._buildItemRow` in `main.dart`

```dart
Widget _buildItemRow(BuildContext context, String item, int index) {
  // Parse item to extract client_id and name
  // Assuming format: "1|192.168.1.100|Device Name"
  final parts = item.split('|').map((s) => s.trim()).toList();
  final clientId = int.tryParse(parts.first) ?? 0;
  final clientName = parts.length > 2 ? parts[2] : parts[1];
  
  return InkWell(
    onTap: (widget.onItemUpdate != null && !widget.isRebooting) ? () async {
      if (widget.category == 'Clients') {
        // Show client groups dialog
        final groups = await DataService.getGroupsForClient(clientId);
        await EditClientGroupsDialog.show(
          context: context,
          clientId: clientId,
          clientName: clientName,
          availableGroups: groups,
          onUpdate: (clientId, groupIds) async {
            await DataService.updateClientGroups(clientId, groupIds);
          },
        );
      } else {
        // Show regular edit dialog for other categories
        await EditItemDialog.show(
          context: context,
          category: widget.category,
          initialName: parts[1],
          initialComment: parts.length > 2 ? parts[2] : null,
          onUpdate: widget.onItemUpdate!,
        );
      }
    } : null,
    child: Container(
      // ... existing row styling ...
    ),
  );
}
```

## Dialog Features

The `EditClientGroupsDialog` provides:

- **Checkable list** of all available groups
- **Current assignment status** shown with checkboxes
- **Summary** showing count of selected groups
- **Save button** with loading indicator
- **Error handling** with SnackBar feedback
- **Validation** before saving
- **Disabled state** during save operation

## Testing

To test the dialog without actual API calls:

```dart
// Create mock groups
final mockGroups = [
  GroupInfo(id: 0, name: 'Default', isAssigned: true),
  GroupInfo(id: 1, name: 'Family Devices', isAssigned: false),
  GroupInfo(id: 2, name: 'IoT Devices', isAssigned: true),
  GroupInfo(id: 3, name: 'Guest Network', isAssigned: false),
];

// Show dialog
await EditClientGroupsDialog.show(
  context: context,
  clientId: 1,
  clientName: '192.168.1.100',
  availableGroups: mockGroups,
  onUpdate: (clientId, groupIds) async {
    print('Client $clientId groups: $groupIds');
    await Future.delayed(Duration(seconds: 1));
  },
);
```

## Notes

- The FTL API uses **integer IDs** for both clients and groups
- The API performs **database-level validation** of IDs
- Assignment changes trigger a **`RELOAD_GRAVITY`** event in FTL
- Batch operations return both **success** and **error** arrays
- The dialog implements a "**replace all**" pattern (delete old, add new)
