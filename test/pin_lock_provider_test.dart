import 'dart:convert';

import 'package:elista/providers/pin_lock_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores only a salted hash and verifies the PIN', () async {
    final storage = _MemoryPinStorage();
    final provider = PinLockProvider(storage: storage);

    await provider.load();
    expect(provider.isEnabled, isFalse);

    await provider.enablePin('1234');
    expect(provider.isEnabled, isTrue);

    final record = jsonDecode(storage.record!) as Map<String, dynamic>;
    expect(record.keys, containsAll(['salt', 'hash']));
    expect(record.values, isNot(contains('1234')));
    expect(record['salt'], isA<String>());
    expect(record['hash'], isA<String>());
    expect(record['hash'], isNot('1234'));
    expect(await provider.verifyPin('1234'), isTrue);
    expect(await provider.verifyPin('0000'), isFalse);
  });

  test('changing and disabling a PIN require the current PIN', () async {
    final storage = _MemoryPinStorage();
    final provider = PinLockProvider(storage: storage);
    await provider.enablePin('1234');

    expect(
      await provider.changePin(currentPin: '0000', newPin: '5678'),
      isFalse,
    );
    expect(
      await provider.changePin(currentPin: '1234', newPin: '5678'),
      isTrue,
    );
    expect(await provider.verifyPin('1234'), isFalse);
    expect(await provider.verifyPin('5678'), isTrue);
    expect(await provider.disablePin('1234'), isFalse);
    expect(await provider.disablePin('5678'), isTrue);
    expect(provider.isEnabled, isFalse);
  });

  test('PINs must contain four to six digits', () async {
    final provider = PinLockProvider(storage: _MemoryPinStorage());

    await expectLater(provider.enablePin('12a4'), throwsArgumentError);
    await expectLater(provider.enablePin('123'), throwsArgumentError);
    await expectLater(provider.enablePin('1234567'), throwsArgumentError);
    await provider.enablePin('123456');
    expect(provider.isEnabled, isTrue);
  });

  test(
    'invalid stored PIN data is surfaced instead of disabling the lock',
    () async {
      final storage = _MemoryPinStorage()..record = '{"salt":"broken"}';
      final provider = PinLockProvider(storage: storage);

      await provider.load();

      expect(provider.isEnabled, isFalse);
      expect(provider.loadError, isA<FormatException>());
    },
  );
}

class _MemoryPinStorage implements PinRecordStorage {
  String? record;

  @override
  Future<String?> readRecord() async => record;

  @override
  Future<void> writeRecord(String value) async {
    record = value;
  }

  @override
  Future<void> clearRecord() async {
    record = null;
  }
}
