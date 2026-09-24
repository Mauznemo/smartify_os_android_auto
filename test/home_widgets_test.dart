import 'dart:async';

import 'package:android_auto_platform_interface/android_auto_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartify_os_android_auto/android_auto.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/widgets/home_widgets/android_auto_navigation_home_widget.dart';
import 'package:smartify_os_android_auto/src/widgets/home_widgets/android_auto_player_home_widget.dart';

/// The two home screen cards, drawn from what a connected phone says. The
/// turn card has to say exactly what the phone said, in its units and its
/// time, and the player's buttons have to reach the phone as keys.
void main() {
  final service = AndroidAutoService.instance;
  final phone = _Phone();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    AndroidAutoPlatform.instance = phone;
  });

  Future<void> connect(WidgetTester tester) async {
    await service.start(const AndroidAutoExtension());
    // Not awaited: it waits a moment on the test's clock, which only moves
    // when pumped.
    unawaited(service.startSession());
    await tester.pump(const Duration(milliseconds: 300));
    phone.connectWithPicture();
    await tester.pump();
  }

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SizedBox(width: 700, height: 118, child: card)),
        ),
      ),
    );
    await tester.pump();
  }

  // One test rather than two on purpose: the service is made once, like at
  // boot, and whatever it listens to keeps running in the zone of the test
  // that made it, which a second test never pumps.
  testWidgets('both cards say what the phone said', (tester) async {
    await connect(tester);

    // The turn card.
    phone.guide(
      const AndroidAutoNavigation(
        status: AndroidAutoNavigationStatus.active,
        maneuver: AndroidAutoManeuver.turnNormalLeft,
        road: 'Main Street',
        stepDistance: AndroidAutoDistance(
          metres: 300,
          displayValue: '300',
          unit: AndroidAutoDistanceUnit.metres,
        ),
        lanes: [
          AndroidAutoLane(
            directions: [
              AndroidAutoLaneDirection(
                shape: AndroidAutoLaneShape.normalLeft,
                highlighted: true,
              ),
            ],
          ),
          AndroidAutoLane(
            directions: [
              AndroidAutoLaneDirection(shape: AndroidAutoLaneShape.straight),
            ],
          ),
        ],
        destinations: [
          AndroidAutoDestination(
            etaText: '14:32',
            distance: AndroidAutoDistance(
              displayValue: '12',
              unit: AndroidAutoDistanceUnit.kilometres,
            ),
            timeToArrival: Duration(minutes: 18),
          ),
        ],
      ),
    );
    await tester.pump();
    await pumpCard(tester, const AndroidAutoNavigationHomeWidget());

    expect(find.text('Main Street'), findsOneWidget);
    expect(find.text('300 m'), findsOneWidget);
    expect(find.text('Arrive 14:32 · 12 km · 18 min'), findsOneWidget);
    // The arrow for the turn, and the lit lane beside it.
    expect(find.byIcon(Icons.turn_left), findsNWidgets(2));
    expect(find.byIcon(Icons.straight), findsOneWidget);

    // The player, with the app playing and only the keys Android Auto has.
    phone.play(
      const AndroidAutoMediaInfo(
        song: 'Midnight Drive',
        artist: 'The Coastliners',
        source: 'Spotify',
        state: AndroidAutoPlaybackState.playing,
      ),
    );
    await tester.pump();
    await pumpCard(tester, const AndroidAutoPlayerHomeWidget());

    expect(find.text('Midnight Drive'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);
    // Android Auto has no keys for these.
    expect(find.byIcon(Icons.shuffle), findsNothing);
    expect(find.byIcon(Icons.repeat), findsNothing);

    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.tap(find.byIcon(Icons.pause));
    expect(phone.keys, [AndroidAutoKey.next, AndroidAutoKey.playPause]);

    unawaited(service.stopSession());
    await tester.pump();
  });
}

/// A phone that connects at once and says what the test tells it to.
class _Phone extends AndroidAutoPlatform {
  final _events = StreamController<AndroidAutoEvent>.broadcast();
  final _media = StreamController<AndroidAutoMediaInfo>.broadcast();
  final _navigation = StreamController<AndroidAutoNavigation>.broadcast();
  final keys = <AndroidAutoKey>[];
  bool _video = false;
  AndroidAutoMediaInfo? _lastMedia;

  void connectWithPicture() {
    _video = true;
    _events.add(const AndroidAutoEvent(AndroidAutoConnectionState.connected));
  }

  void play(AndroidAutoMediaInfo media) {
    _lastMedia = media;
    _media.add(media);
  }

  void guide(AndroidAutoNavigation navigation) => _navigation.add(navigation);

  @override
  Stream<AndroidAutoEvent> get events => _events.stream;

  @override
  Stream<AndroidAutoMediaInfo> get mediaPlayback => _media.stream;

  @override
  AndroidAutoMediaInfo? get lastMediaInfo => _lastMedia;

  @override
  Stream<AndroidAutoNavigation> get navigation => _navigation.stream;

  @override
  Future<bool> get hasVideo async => _video;

  @override
  Future<int?> get textureId async => 1;

  @override
  void pressKey(AndroidAutoKey key) => keys.add(key);

  @override
  Future<void> start(AndroidAutoConfig config) async =>
      _events.add(const AndroidAutoEvent(AndroidAutoConnectionState.searching));

  @override
  Future<void> stop() async {
    _video = false;
    _events.add(const AndroidAutoEvent(AndroidAutoConnectionState.idle));
  }
}
