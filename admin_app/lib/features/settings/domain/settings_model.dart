import 'package:flutter/material.dart';

/// App-wide configuration, branding, and notification preferences.
class AppSettings {
  final ThemeMode themeMode;
  final String collegeName;
  final String collegeLogoUrl;
  final String defaultAcademicYear;
  final bool notifyOnNewResponse;
  final bool notifyOnTargetReached;
  final bool notifyReminder24h;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.collegeName = 'Faculty of Computer Applications & IT',
    this.collegeLogoUrl = '',
    this.defaultAcademicYear = '2025-2026',
    this.notifyOnNewResponse = true,
    this.notifyOnTargetReached = true,
    this.notifyReminder24h = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? collegeName,
    String? collegeLogoUrl,
    String? defaultAcademicYear,
    bool? notifyOnNewResponse,
    bool? notifyOnTargetReached,
    bool? notifyReminder24h,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      collegeName: collegeName ?? this.collegeName,
      collegeLogoUrl: collegeLogoUrl ?? this.collegeLogoUrl,
      defaultAcademicYear: defaultAcademicYear ?? this.defaultAcademicYear,
      notifyOnNewResponse: notifyOnNewResponse ?? this.notifyOnNewResponse,
      notifyOnTargetReached: notifyOnTargetReached ?? this.notifyOnTargetReached,
      notifyReminder24h: notifyReminder24h ?? this.notifyReminder24h,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'collegeName': collegeName,
      'collegeLogoUrl': collegeLogoUrl,
      'defaultAcademicYear': defaultAcademicYear,
      'notifyOnNewResponse': notifyOnNewResponse,
      'notifyOnTargetReached': notifyOnTargetReached,
      'notifyReminder24h': notifyReminder24h,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    ThemeMode mode = ThemeMode.system;
    if (map['themeMode'] == 'light') mode = ThemeMode.light;
    if (map['themeMode'] == 'dark') mode = ThemeMode.dark;

    return AppSettings(
      themeMode: mode,
      collegeName: map['collegeName'] as String? ?? 'Faculty of Computer Applications & IT',
      collegeLogoUrl: map['collegeLogoUrl'] as String? ?? '',
      defaultAcademicYear: map['defaultAcademicYear'] as String? ?? '2025-2026',
      notifyOnNewResponse: map['notifyOnNewResponse'] as bool? ?? true,
      notifyOnTargetReached: map['notifyOnTargetReached'] as bool? ?? true,
      notifyReminder24h: map['notifyReminder24h'] as bool? ?? true,
    );
  }
}
