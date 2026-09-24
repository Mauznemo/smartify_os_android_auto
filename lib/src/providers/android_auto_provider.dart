import 'package:android_auto/android_auto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_state.dart';
import 'package:smartify_os_core/media.dart';

// Written out rather than generated with riverpod_generator: generated
// providers only compile against the exact riverpod they were made for, and
// the car's riverpod is SmartifyOS's to pick. Plain providers work with any.
// Not autoDispose, so they live as long as the car runs, like the service.

/// Everything about Android Auto worth showing, as it changes.
///
/// Read it as
/// `ref.watch(androidAutoStateProvider).value ?? SmartifyOsAndroidAuto.state`,
/// since a stream provider starts out loading.
final androidAutoStateProvider = StreamProvider<AndroidAutoState>(
  (ref) => AndroidAutoService.instance.changes,
);

/// What the connected phone is playing, as the home screen's player card
/// shows it, or `null` while no phone is connected or nothing is playing.
///
/// Read it as
/// `ref.watch(androidAutoNowPlayingProvider).value ?? SmartifyOsAndroidAuto.nowPlaying`.
final androidAutoNowPlayingProvider = StreamProvider<MediaPlayerInfo?>(
  (ref) => AndroidAutoService.instance.nowPlayingChanges,
);

/// The turn by turn guidance in progress, or `null` while no connected phone
/// is guiding anywhere.
///
/// Read it as
/// `ref.watch(androidAutoNavigationProvider).value ?? SmartifyOsAndroidAuto.navigation`.
final androidAutoNavigationProvider = StreamProvider<AndroidAutoNavigation?>(
  (ref) => AndroidAutoService.instance.navigationChanges,
);
