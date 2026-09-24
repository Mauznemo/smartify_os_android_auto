import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_entries.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_wireless_network.dart';
import 'package:smartify_os_core/app_list.dart';
import 'package:smartify_os_core/extensions.dart';
import 'package:smartify_os_core/home_widgets.dart';
import 'package:smartify_os_core/settings.dart';

/// Android Auto on the car's screen: plug a phone in, or connect it over
/// Bluetooth, and it projects.
///
/// ```dart
/// await SmartifyOs().init(
///   bluetooth: const BluetoothConfig(name: 'Miata'),
///   extensions: [
///     const AndroidAutoExtension(),
///   ],
/// );
/// ```
///
/// That adds:
///
/// * **Android Auto** in the app list, which opens it full screen. Closing
///   the window leaves it running in the background.
/// * A notification while it runs, with its icon at the end of the status
///   bar and a button to stop it.
/// * A page in Settings under Connectivity, with a switch to have it start
///   on its own.
/// * Two cards on the home screen while a phone is connected: what it is
///   playing (in place of the Bluetooth player, with the cover), and the next
///   turn while it guides. Each can be switched off in Settings.
///
/// Where a phone was plugged in, it projects over the cable. Otherwise a phone
/// connected over Bluetooth gets a Wi-Fi hotspot brought up for it and
/// projects without a cable, see [wirelessNetwork].
///
/// **Pair phones after installing this.** A phone decides whether a car can
/// do Android Auto without a cable while it pairs, and this is what tells it
/// the car can. One paired before has to be forgotten and paired again once.
///
/// Runs a real head unit on Linux and a pretend phone on macOS and Windows,
/// so the whole thing can be tried while developing. It adds nothing on
/// Android yet. The car needs what the android_auto package lists for Linux,
/// which the SmartifyOS install script sets up.
///
/// android_auto is GPL-3.0, so a car's app that uses this is too.
class AndroidAutoExtension extends SmartifyOsExtension {
  /// The name the phone shows while it is connected. Leave it `null` to use
  /// `AboutConfig.deviceName`.
  final String? headUnitName;

  /// The car's make and model as the phone is told it. Leave it `null` to use
  /// `AboutConfig.model`.
  final String? carModel;

  /// The car's model year as the phone is told it. Leave it `null` for this
  /// year.
  final String? carYear;

  /// Which Wi-Fi network a phone joins to use Android Auto without a cable.
  /// A hotspot the car brings up for it, unless you say otherwise.
  final AndroidAutoWirelessNetwork wirelessNetwork;

  /// USB vendor ids to count as phones when deciding whether a phone is
  /// plugged in, for a phone whose maker SmartifyOS does not know yet. Find
  /// yours with `lsusb`: it is the four digits before the colon.
  ///
  /// This only decides whether to bring the Wi-Fi hotspot up. A phone the car
  /// does not recognise still projects over the cable.
  final Set<int> extraPhoneVendorIds;

  const AndroidAutoExtension({
    this.headUnitName,
    this.carModel,
    this.carYear,
    this.wirelessNetwork = const AndroidAutoWirelessNetwork.hotspot(),
    this.extraPhoneVendorIds = const {},
  });

  @override
  String get id => 'android_auto';

  @override
  String get name => 'Android Auto';

  @override
  Future<void> init(SmartifyOsExtensionContext context) async {
    // Nothing to show where there is no Android Auto to run.
    if (!await AndroidAutoService.instance.start(this)) return;

    SmartifyOsAppList.addEntry(androidAutoAppListEntry());
    SmartifyOsSettings.addPage(androidAutoSettingsPage());
    SmartifyOsHomeWidgets.addWidgets(androidAutoHomeWidgets());
  }
}
