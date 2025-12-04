import 'package:flutter/material.dart';
import '../services/settings_service.dart'; // Import your service

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hostNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accountController = TextEditingController();
  final _sysPasswordController = TextEditingController();
  final _settingsService = SettingsService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load existing values into the text boxes
  Future<void> _loadSettings() async {
    final hostName = await _settingsService.getHostname();
    final appPassword = await _settingsService.getAppPassword();
    final sysAccount = await _settingsService.getSysAccount();
    final sysPassword = await _settingsService.getSysPassword();

    setState(() {
      _hostNameController.text = hostName;
      _passwordController.text = appPassword;
      _accountController.text = sysAccount;
      _sysPasswordController.text = sysPassword;
      _isLoading = false;
    });
  }

  // Save values when user clicks Save
  Future<void> _saveSettings() async {
    await _settingsService.setHostname(_hostNameController.text);
    await _settingsService.setAppPassword(_passwordController.text);
    await _settingsService.setSysAccount(_accountController.text);
    await _settingsService.setSysPassword(_sysPasswordController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Saved')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _cancelSettings() async {

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings Unchanged')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _hostNameController,
              decoration: const InputDecoration(
                labelText: 'PiHole Host URL',
                hintText: 'http://pidns.lan',
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'App Password',
                hintText: '',
              ),
              obscureText: true,
            ),
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: 'System Account',
                hintText: 'admin',
              ),
            ),
            TextField(
              controller: _sysPasswordController,
              decoration: const InputDecoration(
                labelText: 'System Password',
                hintText: '',
              ),
              obscureText: true,
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save, size: 14),
                  label: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: _cancelSettings,
                  label: const Text('Cancel'),
                  icon: const Icon(Icons.cancel, size: 14),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
