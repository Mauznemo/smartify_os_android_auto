import 'dart:io';

import 'package:smartify_os_core/utils.dart';

/// Internal: tells whether an Android phone is plugged in over USB, by reading
/// what Linux already knows about every USB device.
///
/// This only decides *how* Android Auto starts, never whether a phone gets to
/// project: the session always listens on the cable too, and the android_auto
/// plugin asks every USB device it sees whether it speaks Android Auto. So a
/// phone this misses still projects the moment the session is running, and
/// all a miss costs is the Wi-Fi hotspot coming up when it did not have to.
///
/// A phone is a device from a maker of Android phones that is not only a
/// keyboard, a disk, a hub or a sound card (Samsung also makes SSDs, Lenovo
/// keyboards), or one already switched into Android Auto's accessory mode.
class UsbPhoneFinder {
  static const _tag = 'AndroidAuto';

  /// Where Linux lists USB devices. Only ever something else in tests.
  final String devicesPath;

  /// USB vendor ids to count as phone makers on top of [phoneVendorIds].
  final Set<int> extraVendorIds;

  const UsbPhoneFinder({
    this.devicesPath = '/sys/bus/usb/devices',
    this.extraVendorIds = const {},
  });

  /// USB vendor ids of Android phone makers.
  static const phoneVendorIds = <int>{
    0x18d1, // Google
    0x04e8, // Samsung
    0x22b8, // Motorola
    0x1004, // LG
    0x0fce, // Sony
    0x0bb4, // HTC
    0x12d1, // Huawei
    0x2717, // Xiaomi
    0x2a70, // OnePlus
    0x22d9, // Oppo and Realme
    0x2d95, // Vivo
    0x0b05, // Asus
    0x2e04, // HMD (Nokia)
    0x19d2, // ZTE
    0x17ef, // Lenovo
    0x2ae5, // Fairphone
    0x1bbb, // TCL and Alcatel
    0x2a45, // Meizu
    0x05c6, // Qualcomm, whose id many smaller makers ship
    0x0e8d, // MediaTek, likewise
  };

  /// Google's vendor id, which a phone takes on in accessory mode whoever
  /// made it.
  static const _googleVendorId = 0x18d1;

  /// The product ids of Android's accessory mode, with and without ADB and
  /// audio.
  static const _accessoryProductIds = <int>{
    0x2d00,
    0x2d01,
    0x2d02,
    0x2d03,
    0x2d04,
    0x2d05,
  };

  /// USB interface classes a phone never has only of: audio, HID, mass
  /// storage, hub, video and wireless controllers (Bluetooth dongles).
  static const _notPhoneClasses = <int>{0x01, 0x03, 0x08, 0x09, 0x0e, 0xe0};

  /// Whether an Android phone looks to be plugged in. Always `false` off
  /// Linux, and never throws.
  Future<bool> isPhonePluggedIn() async {
    if (!Platform.isLinux && devicesPath == '/sys/bus/usb/devices') {
      return false;
    }
    try {
      final root = Directory(devicesPath);
      if (!await root.exists()) return false;
      final entries = await root.list().toList();
      for (final entry in entries) {
        final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        // Interfaces are called "1-2:1.0", and the root hubs "usb1". Only
        // devices themselves say who made them.
        if (name.contains(':') || name.startsWith('usb')) continue;
        if (await _isPhone(name, entries)) return true;
      }
    } on Object catch (error) {
      SmartifyOsLog.debug(_tag, 'Could not look for a USB phone: $error');
    }
    return false;
  }

  Future<bool> _isPhone(String device, List<FileSystemEntity> entries) async {
    final vendor = await _readHex('$devicesPath/$device/idVendor');
    final product = await _readHex('$devicesPath/$device/idProduct');
    if (vendor == null) return false;

    if (vendor == _googleVendorId && _accessoryProductIds.contains(product)) {
      return true;
    }
    if (!phoneVendorIds.contains(vendor) && !extraVendorIds.contains(vendor)) {
      return false;
    }

    final classes = <int>[];
    for (final entry in entries) {
      final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (!name.startsWith('$device:')) continue;
      final interfaceClass = await _readHex(
        '$devicesPath/$name/bInterfaceClass',
      );
      if (interfaceClass != null) classes.add(interfaceClass);
    }
    // A phone that shows no interfaces at all (charging only, on some
    // phones) still counts, since its maker makes phones.
    return classes.isEmpty || classes.any((c) => !_notPhoneClasses.contains(c));
  }

  static Future<int?> _readHex(String path) async {
    try {
      return int.tryParse((await File(path).readAsString()).trim(), radix: 16);
    } on Object {
      return null;
    }
  }
}
