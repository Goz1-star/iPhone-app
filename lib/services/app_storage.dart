import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/savings_goal.dart';

class AppStorage {
  static const _settingsKey = 'facai.settings';
  static const _goalKey = 'facai.savings_goal';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) {
      return AppSettings.defaults();
    }
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<SavingsGoal> loadSavingsGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_goalKey);
    if (raw == null) {
      return SavingsGoal.defaults();
    }
    return SavingsGoal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, jsonEncode(goal.toJson()));
  }
}
