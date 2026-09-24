import 'dart:async';

import 'package:android_auto_platform_interface/android_auto_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartify_os_android_auto/android_auto.dart';
import 'package:smartify_os_android_auto/src/i18n/strings.g.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';

/// What a real phone does, step by step and on a clock the test controls: it
/// is "connected" a good while before it sends a picture, and when the cable
/// comes out the head unit only says it is looking again. The window draws
/// from the phase, so each of those has to be its own phase, or the driver
/// stares at an empty texture, or at the last frame, and thinks it hung.
void main() {
  final service = AndroidAutoService.instance;
  final phone = _ScriptedPhone();

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    AndroidAutoPlatform.instance = phone;
  });

  test('every step until the picture, and giving up on a lost phone', () {
    fakeAsync((async) {
      service.start(const AndroidAutoExtension());
      async.flushMicrotasks();

      service.startSession();
      // Past the moment a cable-only start holds its errors for.
      async.elapse(const Duration(milliseconds: 300));
      expect(service.state.phase, AndroidAutoPhase.waitingForPhone);

      phone.say(AndroidAutoConnectionState.handshaking);
      async.flushMicrotasks();
      expect(service.state.phase, AndroidAutoPhase.connecting);

      // Agreed, but no picture yet.
      phone.say(AndroidAutoConnectionState.connected, 'Projecting.');
      async.flushMicrotasks();
      expect(service.state.phase, AndroidAutoPhase.startingOnPhone);
      expect(service.state.isConnected, isFalse);

      phone.showPicture();
      async.flushMicrotasks();
      expect(service.state.phase, AndroidAutoPhase.connected);
      expect(service.state.connection, AndroidAutoConnection.cable);

      // The cable comes out.
      phone.say(AndroidAutoConnectionState.searching, 'Lost the link.');
      async.flushMicrotasks();
      expect(service.state.phase, AndroidAutoPhase.reconnecting);

      // It comes back in time: the picture is only there again once the new
      // stream has a frame, never on "connected" alone.
      async.elapse(const Duration(seconds: 10));
      phone.say(AndroidAutoConnectionState.connected, 'Projecting.');
      async.flushMicrotasks();
      expect(service.state.phase, AndroidAutoPhase.startingOnPhone);
      phone.showPicture();
      async.flushMicrotasks();
      expect(service.state.phase, AndroidAutoPhase.connected);

      // Out again, and this time for good.
      phone.say(AndroidAutoConnectionState.searching, 'Lost the link.');
      async.flushMicrotasks();
      async.elapse(
        AndroidAutoService.lostPhoneTimeout - const Duration(seconds: 1),
      );
      expect(service.state.isRunning, isTrue);
      async.elapse(const Duration(seconds: 2));
      expect(service.state.phase, AndroidAutoPhase.stopped);
      expect(service.state.problem, t.android_auto.problem_phone_lost);
      expect(phone.stops, 1);
    });
  });
}

/// A phone that says exactly what the test tells it to.
///
/// Like the real head unit, the picture goes whenever the connection does,
/// and every change to it is followed by an event, which is when the
/// controller asks again.
class _ScriptedPhone extends AndroidAutoPlatform {
  final _events = StreamController<AndroidAutoEvent>.broadcast();
  bool _video = false;
  int stops = 0;

  void say(AndroidAutoConnectionState state, [String? message]) {
    if (state != AndroidAutoConnectionState.connected) _video = false;
    _events.add(AndroidAutoEvent(state, message));
  }

  /// The first frame of a stream, on a phone that is already connected.
  void showPicture() {
    _video = true;
    say(AndroidAutoConnectionState.connected);
  }

  @override
  Future<bool> get hasVideo async => _video;

  @override
  Stream<AndroidAutoEvent> get events => _events.stream;

  @override
  Future<int?> get textureId async => 1;

  @override
  Future<void> start(AndroidAutoConfig config) async =>
      say(AndroidAutoConnectionState.searching);

  @override
  Future<void> stop() async {
    stops++;
    say(AndroidAutoConnectionState.idle);
  }
}
