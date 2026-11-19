import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinLockProvider extends ChangeNotifier {
  PinLockProvider({PinRecordStorage? storage})
    : _storage = storage ?? const _FlutterSecurePinStorage();

  static final RegExp _pinPattern = RegExp(r'^\d{4,6}$');
  final PinRecordStorage _storage;

  bool _isEnabled = false;
  bool _isLoading = false;
  Object? _loadError;

  bool get isEnabled => _isEnabled;
  bool get isLoading => _isLoading;
  Object? get loadError => _loadError;

  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      _isEnabled = await _readRecord() != null;
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> enablePin(String pin) async {
    _validatePin(pin);
    final salt = _generateSalt();
    final hash = _hash(pin, salt);
    await _storage.writeRecord(jsonEncode({'salt': salt, 'hash': hash}));
    _isEnabled = true;
    _loadError = null;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    _validatePin(pin);
    final record = await _readRecord();
    if (record == null) return false;
    return _constantTimeEquals(_hash(pin, record.$1), record.$2);
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    _validatePin(newPin);
    if (!await verifyPin(currentPin)) return false;
    await enablePin(newPin);
    return true;
  }

  Future<bool> disablePin(String currentPin) async {
    if (!await verifyPin(currentPin)) return false;
    await clearPin();
    return true;
  }

  Future<void> clearPin() async {
    await _storage.clearRecord();
    _isEnabled = false;
    _loadError = null;
    notifyListeners();
  }

  Future<(String, String)?> _readRecord() async {
    final value = await _storage.readRecord();
    if (value == null) return null;

    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic> ||
        decoded['salt'] is! String ||
        decoded['hash'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(decoded['salt'] as String) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(decoded['hash'] as String)) {
      throw const FormatException('Stored PIN record is invalid.');
    }
    return (decoded['salt'] as String, decoded['hash'] as String);
  }

  static void _validatePin(String pin) {
    if (!_pinPattern.hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must contain 4 to 6 digits.');
    }
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}

abstract interface class PinRecordStorage {
  Future<String?> readRecord();

  Future<void> writeRecord(String record);

  Future<void> clearRecord();
}

class _FlutterSecurePinStorage implements PinRecordStorage {
  const _FlutterSecurePinStorage();

  static const String _recordKey = 'elista_pin_record';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> readRecord() => _storage.read(key: _recordKey);

  @override
  Future<void> writeRecord(String record) =>
      _storage.write(key: _recordKey, value: record);

  @override
  Future<void> clearRecord() => _storage.delete(key: _recordKey);
}
