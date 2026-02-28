import 'package:shared_preferences/shared_preferences.dart';

enum UserMode {
  explorer, // No API keys, signals only
  pro, // Full trading with API keys
}

class UserModeService {
  static const _key = 'user_mode';

  Future<UserMode> getCurrentMode() async {
    // final prefs = await SharedPreferences.getInstance();
    // final mode = prefs.getString(_key);

    // Pro Mode is currently disabled/unbuilt. Always return Explorer.
    // if (mode == 'pro') return UserMode.pro;
    return UserMode.explorer;
  }

  Future<void> setMode(UserMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == UserMode.pro ? 'pro' : 'explorer');
  }

  Future<bool> isExplorerMode() async {
    final mode = await getCurrentMode();
    return mode == UserMode.explorer;
  }

  Future<bool> isProMode() async {
    final mode = await getCurrentMode();
    return mode == UserMode.pro;
  }

  Future<bool> hasApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('binance_api_key');
    return apiKey != null && apiKey.isNotEmpty;
  }
}
