import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  static const String _nameKey = 'profile_name';
  static const String _cycleKey = 'allowance_cycle';
  static const String _setupCompleteKey = 'setup_complete';

  String _name = '';
  String _allowanceCycle = 'Weekly';
  bool _isSetupComplete = false;

  String get name => _name;
  String get allowanceCycle => _allowanceCycle;
  bool get isSetupComplete => _isSetupComplete;

  Future<void> loadProfile() async {
    final preferences = await SharedPreferences.getInstance();
    _name = preferences.getString(_nameKey) ?? '';
    _allowanceCycle = preferences.getString(_cycleKey) ?? 'Weekly';
    _isSetupComplete = preferences.getBool(_setupCompleteKey) ?? false;
    notifyListeners();
  }

  Future<void> completeSetup({
    required String name,
    required String allowanceCycle,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final nameSaved = await preferences.setString(_nameKey, name.trim());
    final cycleSaved = await preferences.setString(_cycleKey, allowanceCycle);
    final setupSaved = await preferences.setBool(_setupCompleteKey, true);
    if (!nameSaved || !cycleSaved || !setupSaved) {
      throw StateError('Unable to save the setup details.');
    }

    _name = name.trim();
    _allowanceCycle = allowanceCycle;
    _isSetupComplete = true;
    notifyListeners();
  }

  Future<void> skipSetup() async {
    final preferences = await SharedPreferences.getInstance();
    final setupSaved = await preferences.setBool(_setupCompleteKey, true);
    if (!setupSaved) {
      throw StateError('Unable to save the setup preference.');
    }
    _isSetupComplete = true;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.runes.length > 30) {
      throw ArgumentError.value(
        name,
        'name',
        'Name must contain 1 to 30 characters.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_nameKey, trimmedName);
    if (!saved) {
      throw StateError('Unable to save the profile name.');
    }

    _name = trimmedName;
    notifyListeners();
  }
}
