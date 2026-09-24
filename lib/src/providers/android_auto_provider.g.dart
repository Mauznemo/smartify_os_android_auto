// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'android_auto_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Everything about Android Auto worth showing, as it changes.
///
/// Read it as
/// `ref.watch(androidAutoStateProvider).value ?? SmartifyOsAndroidAuto.state`,
/// since a stream provider starts out loading.

@ProviderFor(androidAutoState)
final androidAutoStateProvider = AndroidAutoStateProvider._();

/// Everything about Android Auto worth showing, as it changes.
///
/// Read it as
/// `ref.watch(androidAutoStateProvider).value ?? SmartifyOsAndroidAuto.state`,
/// since a stream provider starts out loading.

final class AndroidAutoStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<AndroidAutoState>,
          AndroidAutoState,
          Stream<AndroidAutoState>
        >
    with $FutureModifier<AndroidAutoState>, $StreamProvider<AndroidAutoState> {
  /// Everything about Android Auto worth showing, as it changes.
  ///
  /// Read it as
  /// `ref.watch(androidAutoStateProvider).value ?? SmartifyOsAndroidAuto.state`,
  /// since a stream provider starts out loading.
  AndroidAutoStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidAutoStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$androidAutoStateHash();

  @$internal
  @override
  $StreamProviderElement<AndroidAutoState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AndroidAutoState> create(Ref ref) {
    return androidAutoState(ref);
  }
}

String _$androidAutoStateHash() => r'52a63908b5e0259463286508fba034558276fa16';

/// What the connected phone is playing, as the home screen's player card
/// shows it, or `null` while no phone is connected or nothing is playing.
///
/// Read it as
/// `ref.watch(androidAutoNowPlayingProvider).value ?? SmartifyOsAndroidAuto.nowPlaying`.

@ProviderFor(androidAutoNowPlaying)
final androidAutoNowPlayingProvider = AndroidAutoNowPlayingProvider._();

/// What the connected phone is playing, as the home screen's player card
/// shows it, or `null` while no phone is connected or nothing is playing.
///
/// Read it as
/// `ref.watch(androidAutoNowPlayingProvider).value ?? SmartifyOsAndroidAuto.nowPlaying`.

final class AndroidAutoNowPlayingProvider
    extends
        $FunctionalProvider<
          AsyncValue<MediaPlayerInfo?>,
          MediaPlayerInfo?,
          Stream<MediaPlayerInfo?>
        >
    with $FutureModifier<MediaPlayerInfo?>, $StreamProvider<MediaPlayerInfo?> {
  /// What the connected phone is playing, as the home screen's player card
  /// shows it, or `null` while no phone is connected or nothing is playing.
  ///
  /// Read it as
  /// `ref.watch(androidAutoNowPlayingProvider).value ?? SmartifyOsAndroidAuto.nowPlaying`.
  AndroidAutoNowPlayingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidAutoNowPlayingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$androidAutoNowPlayingHash();

  @$internal
  @override
  $StreamProviderElement<MediaPlayerInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MediaPlayerInfo?> create(Ref ref) {
    return androidAutoNowPlaying(ref);
  }
}

String _$androidAutoNowPlayingHash() =>
    r'ee294877e02ef24b26dd34012ae0327f8f089227';

/// The turn by turn guidance in progress, or `null` while no connected phone
/// is guiding anywhere.
///
/// Read it as
/// `ref.watch(androidAutoNavigationProvider).value ?? SmartifyOsAndroidAuto.navigation`.

@ProviderFor(androidAutoNavigation)
final androidAutoNavigationProvider = AndroidAutoNavigationProvider._();

/// The turn by turn guidance in progress, or `null` while no connected phone
/// is guiding anywhere.
///
/// Read it as
/// `ref.watch(androidAutoNavigationProvider).value ?? SmartifyOsAndroidAuto.navigation`.

final class AndroidAutoNavigationProvider
    extends
        $FunctionalProvider<
          AsyncValue<AndroidAutoNavigation?>,
          AndroidAutoNavigation?,
          Stream<AndroidAutoNavigation?>
        >
    with
        $FutureModifier<AndroidAutoNavigation?>,
        $StreamProvider<AndroidAutoNavigation?> {
  /// The turn by turn guidance in progress, or `null` while no connected phone
  /// is guiding anywhere.
  ///
  /// Read it as
  /// `ref.watch(androidAutoNavigationProvider).value ?? SmartifyOsAndroidAuto.navigation`.
  AndroidAutoNavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'androidAutoNavigationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$androidAutoNavigationHash();

  @$internal
  @override
  $StreamProviderElement<AndroidAutoNavigation?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AndroidAutoNavigation?> create(Ref ref) {
    return androidAutoNavigation(ref);
  }
}

String _$androidAutoNavigationHash() =>
    r'8fb6b02fe5e1af9e8c80fc6ad9fcf22c5ffc3aa7';
