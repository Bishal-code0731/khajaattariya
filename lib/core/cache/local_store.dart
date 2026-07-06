import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Disk-persisted cache for read models (restaurants, categories, menu
/// items, the signed-in user's profile) and the offline retry queue.
///
/// Backed by shared_preferences (already a dependency for theme
/// persistence) storing each entry as a JSON string plus a separate
/// "last updated" timestamp — enough for this app's data sizes without
/// pulling in a database package. Every read/write here works with the
/// same raw `Map<String, dynamic>` shape Supabase already returns, so
/// callers just round-trip through each model's existing `fromMap`.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _sp async => _prefs ??= await SharedPreferences.getInstance();

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
      // Corrupt/incompatible entry (e.g. a model shape change) — treat
      // as no cache rather than crashing the caller.
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
