import 'package:android_auto/android_auto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_state.dart';
import 'package:smartify_os_core/media.dart';

part 'android_auto_provider.g.dart';

/// Everything about Android Auto worth showing, as it changes.
///
/// Read it as
/// `ref.watch(androidAutoStateProvider).value ?? SmartifyOsAndroidAuto.state`,
/// since a stream provider starts out loading.
@Riverpod(keepAlive: true)
Stream<AndroidAutoState> androidAutoState(Ref ref) =>
    AndroidAutoService.instance.changes;

/// What the connected phone is playing, as the home screen's player card
/// shows it, or `null` while no phone is connected or nothing is playing.
///
/// Read it as
/// `ref.watch(androidAutoNowPlayingProvider).value ?? SmartifyOsAndroidAuto.nowPlaying`.
@Riverpod(keepAlive: true)
Stream<MediaPlayerInfo?> androidAutoNowPlaying(Ref ref) =>
    AndroidAutoService.instance.nowPlayingChanges;

/// The turn by turn guidance in progress, or `null` while no connected phone
/// is guiding anywhere.
///
/// Read it as
/// `ref.watch(androidAutoNavigationProvider).value ?? SmartifyOsAndroidAuto.navigation`.
@Riverpod(keepAlive: true)
Stream<AndroidAutoNavigation?> androidAutoNavigation(Ref ref) =>
    AndroidAutoService.instance.navigationChanges;
