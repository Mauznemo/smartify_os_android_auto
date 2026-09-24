import 'package:android_auto/android_auto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartify_os_android_auto/android_auto.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_core/notifications.dart';

/// One whole drive against android_auto's pretend phone, which is what macOS
/// and Windows run: the session finds the phone, the ongoing notification
/// follows it, and stopping takes everything away again.
///
/// Real time rather than fake, since the pretend phone takes about two
/// seconds to connect, the way a real one would.
void main() {
  final service = AndroidAutoService.instance;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    AndroidAutoSimulator.registerWith();
    expect(await service.start(const AndroidAutoExtension()), isTrue);
  });

  Future<void> waitFor(bool Function(AndroidAutoState state) test) =>
      service.changes.firstWhere(test).timeout(const Duration(seconds: 10));

  test('starts stopped, and remembers nothing yet', () {
    expect(service.state.phase, AndroidAutoPhase.stopped);
    expect(service.state.autostart, isFalse);
    expect(service.state.wirelessAvailable, isTrue);
    expect(
      SmartifyOsNotifications.hasNotification(AndroidAutoIds.notification),
      isFalse,
    );
  });

  test('a session finds the phone and says so in the shade', () async {
    await service.startSession();
    expect(service.state.isRunning, isTrue);
    expect(
      SmartifyOsNotifications.hasNotification(AndroidAutoIds.notification),
      isTrue,
    );

    await waitFor((state) => state.isConnected);
    // The pretend phone is on no Wi-Fi of the car's, so it counts as cabled.
    expect(service.state.connection, AndroidAutoConnection.cable);
    expect(service.state.problem, isNull);
  });

  test('stopping takes the notification away', () async {
    await service.stopSession();

    expect(service.state.phase, AndroidAutoPhase.stopped);
    expect(service.state.connection, isNull);
    expect(
      SmartifyOsNotifications.hasNotification(AndroidAutoIds.notification),
      isFalse,
    );
  });

  test('the driver\'s choices are remembered', () async {
    await service.setAutostart(true);
    await service.setWireless(false);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('smartify_os.android_auto.autostart'), isTrue);
    expect(prefs.getBool('smartify_os.android_auto.wireless'), isFalse);
    expect(service.state.usesWireless, isFalse);
  });
}
