import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crop_collection.dart';

/// Simple local storage for crop collection sessions using SharedPreferences.
class CropCollectionStorage {
  static const String _key = 'crop_collection_sessions_v1';

  Future<List<CropCollectionSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((e) => CropCollectionSession.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<CropCollectionSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
