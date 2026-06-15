import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Local non-volatile persistence layer.
///
/// Mirrors the storage contract from the spec:
///   * `master_roster`   – cached unique players for the autocomplete pool.
///   * `active_session`  – high-fidelity snapshot of the ongoing session.
///   * `session_archive` – completed tournaments, searchable by timestamp.
///   * `default_rules`   – default game parameters for new sessions.
///
/// Backed by `shared_preferences`, which works uniformly across iOS, Android
/// and the web (localStorage), insulating the session against OS memory
/// reclamation and unexpected crashes.
class StorageService {
  static const _kMasterRoster = 'master_roster';
  static const _kActiveSession = 'active_session';
  static const _kArchive = 'session_archive';
  static const _kRules = 'default_rules';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  // --- Master roster ------------------------------------------------------

  Future<void> saveMasterRoster(List<Player> players) async {
    final prefs = await _instance;
    await prefs.setString(
      _kMasterRoster,
      jsonEncode(players.map((p) => p.toJson()).toList()),
    );
  }

  Future<List<Player>> loadMasterRoster() async {
    final prefs = await _instance;
    final raw = prefs.getString(_kMasterRoster);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Player.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // --- Active session -----------------------------------------------------

  Future<void> saveActiveSession(SessionState? session) async {
    final prefs = await _instance;
    if (session == null) {
      await prefs.remove(_kActiveSession);
    } else {
      await prefs.setString(_kActiveSession, jsonEncode(session.toJson()));
    }
  }

  Future<SessionState?> loadActiveSession() async {
    final prefs = await _instance;
    final raw = prefs.getString(_kActiveSession);
    if (raw == null) return null;
    try {
      return SessionState.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  // --- Archive ------------------------------------------------------------

  Future<void> saveArchive(List<ArchivedSession> archive) async {
    final prefs = await _instance;
    await prefs.setString(
      _kArchive,
      jsonEncode(archive.map((a) => a.toJson()).toList()),
    );
  }

  Future<List<ArchivedSession>> loadArchive() async {
    final prefs = await _instance;
    final raw = prefs.getString(_kArchive);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              ArchivedSession.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // --- Default rules ------------------------------------------------------

  Future<void> saveRules(Rules rules) async {
    final prefs = await _instance;
    await prefs.setString(_kRules, jsonEncode(rules.toJson()));
  }

  Future<Rules> loadRules() async {
    final prefs = await _instance;
    final raw = prefs.getString(_kRules);
    if (raw == null) return const Rules();
    try {
      return Rules.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return const Rules();
    }
  }
}
