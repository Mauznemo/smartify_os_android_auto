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
