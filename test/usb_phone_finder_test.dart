import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/usb_phone_finder.dart';

/// The cable check decides whether the car brings its Wi-Fi hotspot up, so
/// the two ways it can be wrong cost different things: missing a phone brings
/// the hotspot up for nothing, and taking a disk for a phone keeps a phone on
/// Bluetooth waiting. These build a fake `/sys/bus/usb/devices` the way Linux
/// lays it out and check both.
void main() {
  late Directory sysfs;

  setUp(() async {
    sysfs = await Directory.systemTemp.createTemp('usb_devices');
  });

  tearDown(() async {
    await sysfs.delete(recursive: true);
  });

  Future<void> device(
    String name, {
    required String vendor,
    String product = '0001',
    List<String> interfaceClasses = const [],
  }) async {
    final dir = await Directory('${sysfs.path}/$name').create();
    await File('${dir.path}/idVendor').writeAsString('$vendor\n');
    await File('${dir.path}/idProduct').writeAsString('$product\n');
    for (var i = 0; i < interfaceClasses.length; i++) {
      final interface = await Directory('${sysfs.path}/$name:1.$i').create();
      await File(
        '${interface.path}/bInterfaceClass',
      ).writeAsString('${interfaceClasses[i]}\n');
    }
  }

  UsbPhoneFinder finder({Set<int> extra = const {}}) =>
      UsbPhoneFinder(devicesPath: sysfs.path, extraVendorIds: extra);

  test('nothing plugged in is no phone', () async {
    await device('usb1', vendor: '1d6b', interfaceClasses: ['09']);

    expect(await finder().isPhonePluggedIn(), isFalse);
  });

  test('a Pixel sharing files is a phone', () async {
    await device(
      '1-2',
      vendor: '18d1',
      product: '4ee1',
      interfaceClasses: ['06'],
    );

    expect(await finder().isPhonePluggedIn(), isTrue);
  });

  test('a phone only charging, with no interfaces, is a phone', () async {
    await device('1-2', vendor: '04e8');

    expect(await finder().isPhonePluggedIn(), isTrue);
  });

  test('a phone already in accessory mode is a phone', () async {
    await device(
      '1-2',
      vendor: '18d1',
      product: '2d01',
      interfaceClasses: ['ff'],
    );

    expect(await finder().isPhonePluggedIn(), isTrue);
  });

  test('a Samsung SSD is not a phone', () async {
    await device('1-3', vendor: '04e8', interfaceClasses: ['08']);

    expect(await finder().isPhonePluggedIn(), isFalse);
  });

  test('a Lenovo keyboard is not a phone', () async {
    await device('1-4', vendor: '17ef', interfaceClasses: ['03', '03']);

    expect(await finder().isPhonePluggedIn(), isFalse);
  });

  test('an unknown maker only counts once it is added', () async {
    await device('1-5', vendor: 'abcd', interfaceClasses: ['ff']);

    expect(await finder().isPhonePluggedIn(), isFalse);
    expect(await finder(extra: {0xabcd}).isPhonePluggedIn(), isTrue);
  });

  test('a missing directory is no phone rather than an error', () async {
    await sysfs.delete(recursive: true);
    await sysfs.create();
    final gone = UsbPhoneFinder(devicesPath: '${sysfs.path}/nope');

    expect(await gone.isPhonePluggedIn(), isFalse);
  });
}
