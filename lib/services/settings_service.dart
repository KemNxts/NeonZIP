import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PathStyle { classic, terminalDot }

class SettingsService extends ChangeNotifier {
  bool _firstRunCompleted = false;
  PathStyle _pathStyle = PathStyle.terminalDot;

  bool get firstRunCompleted => _firstRunCompleted;
  PathStyle get pathStyle => _pathStyle;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    
    _firstRunCompleted = prefs.getBool('settings_first_run') ?? false;
    
    final styleString = prefs.getString('settings_path_style');
    if (styleString == 'classic') {
      _pathStyle = PathStyle.classic;
    } else if (styleString == 'terminalDot') {
      _pathStyle = PathStyle.terminalDot;
    }
    
    _initialized = true;
    notifyListeners();
  }

  Future<void> setFirstRunCompleted() async {
    _firstRunCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_first_run', true);
    notifyListeners();
  }

  Future<void> setPathStyle(PathStyle style) async {
    if (_pathStyle == style) return;
    _pathStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_path_style', style.name);
    notifyListeners();
  }
}
