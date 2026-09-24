/// Android Auto for SmartifyOS: plug a phone in, or connect it over
/// Bluetooth, and it projects.
///
/// ```dart
/// await SmartifyOs().init(
///   extensions: [
///     const AndroidAutoExtension(),
///   ],
/// );
/// ```
///
/// That is all a car needs. [SmartifyOsAndroidAuto] drives it from your own
/// code, and its `controller` is where to build your own screens on top of
/// what the phone is doing.
library;

export 'src/android_auto_extension.dart';
export 'src/providers/android_auto_provider.dart';
export 'src/services/android_auto/android_auto_entries.dart'
    show AndroidAutoIds;
export 'src/services/android_auto/models/android_auto_state.dart';
export 'src/services/android_auto/models/android_auto_wireless_network.dart';
export 'src/services/android_auto/smartify_os_android_auto.dart';
export 'src/widgets/android_auto_icon.dart';
export 'src/windows/android_auto_window.dart';
