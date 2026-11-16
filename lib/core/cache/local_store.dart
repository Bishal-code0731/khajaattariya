import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  static String _dataKey(String key) => 'offline_cache::$key';
  static String _timeKey(String key) => 'offline_cache_ts::$key';

  Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    final sp = await _sp;
    await sp.setString(_dataKey(key), jsonEncode(items));
    await sp.setInt(_timeKey(key), DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>?> loadList(String key) async {
    final sp = await _sp;
    final raw = sp.getString(_dataKey(key));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      // Corrupt/incompatible entry (e.g.
      return null;
    }
  }

  Future<void> saveMap(String key, Map<String, dynamic> value) async {
    final sp = await _sp;
    await sp.setString(_dataKey(key), jsonEncode(value));
    await sp.setInt(_timeKey(key), DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>?> loadMap(String key) async {
    final sp = await _sp;
    final raw = sp.getString(_dataKey(key));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> lastUpdated(String key) async {
    final sp = await _sp;
    final ms = sp.getInt(_timeKey(key));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clear(String key) async {
    final sp = await _sp;
    await sp.remove(_dataKey(key));
    await sp.remove(_timeKey(key));
  }
}
