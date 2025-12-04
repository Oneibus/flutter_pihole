import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _configurationStatus = 'pihole_configuration_status';
  static const String _keyHostname = 'pihole_hostname';
  static const String _keyAppPassword = 'pihole_app_password';
  static const String _keySysAccount = 'pihole_system_account';
  static const String _keySysPassword = 'pihole_system_password';

  // Defaults (Compile-time constants)
  static const String _defaultHostname = String.fromEnvironment(
      'PIHOLE_APP_HOSTNAME',
      defaultValue: 'localhost'
  );
  static const String _defaultAppPassword = String.fromEnvironment(
      'PIHOLE_APP_PASSWORD',
      defaultValue: ''
  );
  static const String _defaultSysAccount = String.fromEnvironment(
      'PIHOLE_SYS_ACCOUNT',
      defaultValue: 'admin'
  );
  static const String _defaultSysPassword = String.fromEnvironment(
      'PIHOLE_SYS_PASSWORD',
      defaultValue: ''
  );

  // get configuration status
  Future<bool> getConfigurationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_configurationStatus) ?? false;
  }

  // Getters that check Storage first, then Default
  Future<String> getHostname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHostname) ?? _defaultHostname;
  }

  Future<void> setHostname(String hostname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHostname, hostname);
    await prefs.setBool(_configurationStatus, true);
  }

  Future<String> getAppPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppPassword) ?? _defaultAppPassword;
  }

  Future<void> setAppPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppPassword, password);
  }

  Future<String> getSysAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySysAccount) ?? _defaultSysAccount;
  }

  Future<void> setSysAccount(String account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySysAccount, account);
  }

  Future<String> getSysPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySysPassword) ?? _defaultSysPassword;
  }

  Future<void> setSysPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySysPassword, password);
  }
}
