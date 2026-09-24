import 'dart:async';

import 'package:android_auto_platform_interface/android_auto_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
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

      // The window measured its view on an earlier drive. Starting with it
      // closed, the phone has to be told that size before it connects, or it
      // lays out 16:9 and then again once the window opens.
      service.rememberViewSize(const Size(1016, 506));
      service.startSession();
      // Past the moment a cable-only start holds its errors for.
      async.elapse(const Duration(milliseconds: 300));
      expect(service.state.phase, AndroidAutoPhase.waitingForPhone);
      expect(phone.viewSizeAtStart, const Size(1016, 506));

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

      // What it plays, with the position counted on from the moment the
      // phone said it.
      phone.play(
        const AndroidAutoMediaInfo(
          song: 'Midnight Drive',
          state: AndroidAutoPlaybackState.playing,
          duration: Duration(minutes: 3),
          position: Duration(seconds: 10),
        ),
      );
      async.flushMicrotasks();
      final playing = service.nowPlaying!;
      expect(playing.title, 'Midnight Drive');
      expect(playing.isPlaying, isTrue);
      expect(playing.positionReportedAt, isNotNull);

      // News about something else must not restart the count from a
      // position that is seconds old by then.
      async.elapse(const Duration(seconds: 3));
      phone.play(
        const AndroidAutoMediaInfo(
          song: 'Midnight Drive',
          album: 'Coastline',
          state: AndroidAutoPlaybackState.playing,
          duration: Duration(minutes: 3),
          position: Duration(seconds: 10),
        ),
      );
      async.flushMicrotasks();
      expect(
        service.nowPlaying!.positionReportedAt,
        playing.positionReportedAt,
      );
      expect(service.nowPlaying!.album, 'Coastline');

      // Directions only while the phone is actually guiding.
      phone.guide(
        const AndroidAutoNavigation(
          status: AndroidAutoNavigationStatus.active,
          road: 'Main Street',
        ),
      );
      async.flushMicrotasks();
      expect(service.navigation?.road, 'Main Street');
      phone.guide(
        const AndroidAutoNavigation(
          status: AndroidAutoNavigationStatus.inactive,
          road: 'Main Street',
        ),
      );
      async.flushMicrotasks();
      expect(service.navigation, isNull);
      phone.guide(
        const AndroidAutoNavigation(
          status: AndroidAutoNavigationStatus.active,
          road: 'Main Street',
        ),
      );
      async.flushMicrotasks();

      // The cable comes out.
      phone.say(AndroidAutoConnectionState.searching, 'Lost the link.');
      async.flushMicrotasks();
      expect(service.state.phase, AndroidAutoPhase.reconnecting);
      // Nothing it said is true any more, and an old turn on the home screen
      // would be the worst thing to leave behind.
      expect(service.nowPlaying, isNull);
      expect(service.navigation, isNull);

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
  final _media = StreamController<AndroidAutoMediaInfo>.broadcast();
  final _navigation = StreamController<AndroidAutoNavigation>.broadcast();
  bool _video = false;
  Size? _viewSize;
  int stops = 0;

  /// The view size the head unit knew when it was started.
  Size? viewSizeAtStart;

  void say(AndroidAutoConnectionState state, [String? message]) {
    if (state != AndroidAutoConnectionState.connected) _video = false;
    _events.add(AndroidAutoEvent(state, message));
  }

  /// The first frame of a stream, on a phone that is already connected.
  void showPicture() {
    _video = true;
    say(AndroidAutoConnectionState.connected);
  }

  void play(AndroidAutoMediaInfo media) => _media.add(media);

  void guide(AndroidAutoNavigation navigation) => _navigation.add(navigation);

  @override
  Stream<AndroidAutoMediaInfo> get mediaPlayback => _media.stream;

  @override
  Stream<AndroidAutoNavigation> get navigation => _navigation.stream;

  @override
  Future<bool> get hasVideo async => _video;

  @override
  Stream<AndroidAutoEvent> get events => _events.stream;

  @override
  Future<int?> get textureId async => 1;

  @override
  void setViewSize(double width, double height) =>
      _viewSize = Size(width, height);

  @override
  Future<void> start(AndroidAutoConfig config) async {
    viewSizeAtStart = _viewSize;
    say(AndroidAutoConnectionState.searching);
  }

  @override
  Future<void> stop() async {
    stops++;
    say(AndroidAutoConnectionState.idle);
  }
}
