import 'package:elista/providers/pin_lock_provider.dart';
import 'package:elista/screens/pin_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('PIN gate unlocks and relocks after a long background pause', (
    tester,
  ) async {
    final provider = PinLockProvider(storage: _MemoryPinStorage());
    await provider.enablePin('1234');
    var now = DateTime(2026, 1, 1);

    await tester.pumpWidget(_app(provider, clock: () => now));
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text('Protected screen'), findsNothing);

    await _enterPin(tester, '1234');
    expect(find.text('Protected screen'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 31));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text('Protected screen'), findsNothing);
  });

  testWidgets('PIN keypad locks for 30 seconds after five incorrect attempts', (
    tester,
  ) async {
    final provider = PinLockProvider(storage: _MemoryPinStorage());
    await provider.enablePin('1234');

    await tester.pumpWidget(_app(provider));
    for (var attempt = 0; attempt < 5; attempt++) {
      for (var digit = 0; digit < 4; digit++) {
        await tester.tap(find.text('0'));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 450));
    }

    expect(find.textContaining('Try again in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(PinLockProvider provider, {DateTime Function()? clock}) {
  return ChangeNotifierProvider<PinLockProvider>.value(
    value: provider,
    child: MaterialApp(
      home: PinLockGate(clock: clock, child: const Text('Protected screen')),
    ),
  );
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
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
