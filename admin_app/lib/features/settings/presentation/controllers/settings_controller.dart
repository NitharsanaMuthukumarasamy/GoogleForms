import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/settings_model.dart';

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// StateNotifier to manage AppSettings with local and Firestore persistence.
class SettingsController extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;

  static const _kThemeModeKey = 'settings_theme_mode';
  static const _kCollegeNameKey = 'settings_college_name';
  static const _kCollegeLogoKey = 'settings_college_logo_url';
  static const _kDefaultYearKey = 'settings_default_academic_year';
  static const _kNotifyNewRespKey = 'settings_notify_new_response';
  static const _kNotifyTargetKey = 'settings_notify_target_reached';
  static const _kNotifyReminderKey = 'settings_notify_reminder_24h';

  SettingsController(this._prefs, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const AppSettings()) {
    _loadFromLocalPrefs();
    _listenToCloudSettings();
  }

  void _loadFromLocalPrefs() {
    final themeStr = _prefs.getString(_kThemeModeKey) ?? 'system';
    ThemeMode mode = ThemeMode.system;
    if (themeStr == 'light') mode = ThemeMode.light;
    if (themeStr == 'dark') mode = ThemeMode.dark;

    final collegeName = _prefs.getString(_kCollegeNameKey) ?? state.collegeName;
    final collegeLogo = _prefs.getString(_kCollegeLogoKey) ?? state.collegeLogoUrl;
    final defaultYear = _prefs.getString(_kDefaultYearKey) ?? state.defaultAcademicYear;
    final notifyNew = _prefs.getBool(_kNotifyNewRespKey) ?? state.notifyOnNewResponse;
    final notifyTarget = _prefs.getBool(_kNotifyTargetKey) ?? state.notifyOnTargetReached;
    final notifyRemind = _prefs.getBool(_kNotifyReminderKey) ?? state.notifyReminder24h;

    state = AppSettings(
      themeMode: mode,
      collegeName: collegeName,
      collegeLogoUrl: collegeLogo,
      defaultAcademicYear: defaultYear,
      notifyOnNewResponse: notifyNew,
      notifyOnTargetReached: notifyTarget,
      notifyReminder24h: notifyRemind,
    );
  }

  void _listenToCloudSettings() {
    _firestore.collection('settings').doc('college_profile').snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final cloudName = data['collegeName'] as String?;
        final cloudLogo = data['collegeLogoUrl'] as String?;
        final cloudYear = data['defaultAcademicYear'] as String?;

        if (cloudName != null || cloudLogo != null || cloudYear != null) {
          state = state.copyWith(
            collegeName: cloudName ?? state.collegeName,
            collegeLogoUrl: cloudLogo ?? state.collegeLogoUrl,
            defaultAcademicYear: cloudYear ?? state.defaultAcademicYear,
          );
        }
      }
    }, onError: (_) {
      // Offline fallback: keep local preferences
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kThemeModeKey, mode.name);
  }

  Future<void> setCollegeName(String name) async {
    state = state.copyWith(collegeName: name.trim());
    await _prefs.setString(_kCollegeNameKey, name.trim());
    _syncToFirestore();
  }

  Future<void> setCollegeLogoUrl(String url) async {
    state = state.copyWith(collegeLogoUrl: url.trim());
    await _prefs.setString(_kCollegeLogoKey, url.trim());
    _syncToFirestore();
  }

  Future<void> setDefaultAcademicYear(String year) async {
    state = state.copyWith(defaultAcademicYear: year.trim());
    await _prefs.setString(_kDefaultYearKey, year.trim());
    _syncToFirestore();
  }

  Future<void> setNotifyOnNewResponse(bool value) async {
    state = state.copyWith(notifyOnNewResponse: value);
    await _prefs.setBool(_kNotifyNewRespKey, value);
  }

  Future<void> setNotifyOnTargetReached(bool value) async {
    state = state.copyWith(notifyOnTargetReached: value);
    await _prefs.setBool(_kNotifyTargetKey, value);
  }

  Future<void> setNotifyReminder24h(bool value) async {
    state = state.copyWith(notifyReminder24h: value);
    await _prefs.setBool(_kNotifyReminderKey, value);
  }

  Future<void> _syncToFirestore() async {
    try {
      await _firestore.collection('settings').doc('college_profile').set({
        'collegeName': state.collegeName,
        'collegeLogoUrl': state.collegeLogoUrl,
        'defaultAcademicYear': state.defaultAcademicYear,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Queued for offline sync by Firestore
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsController(prefs);
});
