import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartify_os_core/utils.dart';

/// Internal: what Android Auto remembers between drives.
///
/// Everything here is best effort. A preferences store that cannot be read or
/// written only costs the driver their choices, it must never stop the car
/// from booting, so failures are logged and swallowed.
class AndroidAutoStore {
  static const _tag = 'AndroidAuto';

  // Every key starts with the extension's id, so no other extension can ever
  // take one of them.
  static const _autostartKey = 'smartify_os.android_auto.autostart';
  static const _wirelessKey = 'smartify_os.android_auto.wireless';
  static const _askedKey = 'smartify_os.android_auto.asked_about_autostart';
  static const _passphraseKey = 'smartify_os.android_auto.hotspot_passphrase';
  static const _phonesKey = 'smartify_os.android_auto.wireless_phones';

  const AndroidAutoStore();

  /// Reads everything that was saved, with the defaults for anything that
  /// was not. A hotspot password is made up and saved the first time.
  Future<AndroidAutoSaved> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var passphrase = prefs.getString(_passphraseKey);
      if (passphrase == null || passphrase.length < 8) {
        passphrase = _newPassphrase();
        await prefs.setString(_passphraseKey, passphrase);
      }
      return AndroidAutoSaved(
        autostart: prefs.getBool(_autostartKey) ?? false,
        wireless: prefs.getBool(_wirelessKey) ?? true,
        askedAboutAutostart: prefs.getBool(_askedKey) ?? false,
        hotspotPassphrase: passphrase,
        wirelessPhones: {...?prefs.getStringList(_phonesKey)},
      );
    } on Object catch (error) {
      SmartifyOsLog.warning(_tag, 'Could not read the saved settings', error);
      return AndroidAutoSaved(hotspotPassphrase: _newPassphrase());
    }
  }

  Future<void> saveAutostart(bool on) =>
      _write((prefs) => prefs.setBool(_autostartKey, on));

  Future<void> saveWireless(bool on) =>
      _write((prefs) => prefs.setBool(_wirelessKey, on));

  Future<void> saveAskedAboutAutostart() =>
      _write((prefs) => prefs.setBool(_askedKey, true));

  Future<void> saveWirelessPhones(Set<String> addresses) =>
      _write((prefs) => prefs.setStringList(_phonesKey, addresses.toList()));

  Future<void> _write(
    Future<void> Function(SharedPreferences prefs) write,
  ) async {
    try {
      await write(await SharedPreferences.getInstance());
    } on Object catch (error) {
      SmartifyOsLog.warning(_tag, 'Could not save a setting', error);
    }
  }

  /// A WPA2 password nobody ever types: the car hands it to the phone over
  /// Bluetooth. Letters and digits only, so nothing along the way has to
  /// quote it.
  static String _newPassphrase() {
    const alphabet =
        'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return String.fromCharCodes([
      for (var i = 0; i < 20; i++)
        alphabet.codeUnitAt(random.nextInt(alphabet.length)),
    ]);
  }
}

/// Internal: what [AndroidAutoStore.load] found.
class AndroidAutoSaved {
  final bool autostart;
  final bool wireless;
  final bool askedAboutAutostart;
  final String hotspotPassphrase;
  final Set<String> wirelessPhones;

  const AndroidAutoSaved({
    required this.hotspotPassphrase,
    this.autostart = false,
    this.wireless = true,
    this.askedAboutAutostart = false,
    this.wirelessPhones = const {},
  });
}
