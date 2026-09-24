import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_state.dart';

part 'android_auto_provider.g.dart';

/// Everything about Android Auto worth showing, as it changes.
///
/// Read it as
/// `ref.watch(androidAutoStateProvider).value ?? SmartifyOsAndroidAuto.state`,
/// since a stream provider starts out loading.
@Riverpod(keepAlive: true)
Stream<AndroidAutoState> androidAutoState(Ref ref) =>
    AndroidAutoService.instance.changes;
