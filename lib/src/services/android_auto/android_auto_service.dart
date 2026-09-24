import 'dart:async';
import 'dart:io';

import 'package:android_auto/android_auto.dart';
import 'package:flutter/material.dart';
import 'package:smartify_os_android_auto/src/android_auto_extension.dart';
import 'package:smartify_os_android_auto/src/i18n/strings.g.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_store.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_state.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/models/android_auto_wireless_network.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/usb_phone_finder.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/wifi_hotspot.dart';
import 'package:smartify_os_android_auto/src/utils/android_auto_status_text.dart';
import 'package:smartify_os_android_auto/src/widgets/android_auto_icon.dart';
import 'package:smartify_os_android_auto/src/windows/android_auto_window.dart';
import 'package:smartify_os_core/bluetooth.dart';
import 'package:smartify_os_core/core.dart';
import 'package:smartify_os_core/date_time.dart';
import 'package:smartify_os_core/modals.dart';
import 'package:smartify_os_core/notifications.dart';
import 'package:smartify_os_core/settings.dart';
import 'package:smartify_os_core/utils.dart';

/// Internal: runs Android Auto for the whole car, whether or not its window is
/// open.
///
/// It owns the one [AndroidAutoController] the app has, made at boot and kept
/// until the car is switched off. Making it at boot is what publishes the
/// Android Auto service on Bluetooth, so every phone paired from then on
/// learns the car can do Android Auto without a cable, whether or not it is
/// running. A phone only reads that at pairing time, which is why a phone
/// paired before the extension was installed has to be paired again.
///
/// A session goes:
///
/// 1. A phone on the cable wins, since that is easy and the driver plugged it
///    in on purpose.
/// 2. Otherwise a phone connected over Bluetooth gets the Wi-Fi hotspot
///    brought up for it and is offered Android Auto without a cable.
/// 3. Otherwise it waits, on the cable, and switches to 2 as soon as a phone
///    connects over Bluetooth.
///
/// The cable is listened on throughout, so plugging in later always works.
class AndroidAutoService {
  static const _tag = 'AndroidAuto';

  /// The ongoing notification that stands for a running session.
  static const notificationId = 'android_auto';

  /// How long a session waits for a phone before it ends by itself, when it
  /// started on its own or its phone went away. A session the driver started
  /// and that has not had a phone yet waits until they stop it.
  static const idleTimeout = Duration(seconds: 60);

  /// How long a session that found a phone on the cable gives it before a
  /// phone on Bluetooth gets offered Wi-Fi instead. The cable check only
  /// knows who made a device, so a charging cable to something else could
  /// otherwise keep the phone in the driver's pocket waiting forever.
  static const cableGrace = Duration(seconds: 10);

  /// After a stop, how long a phone arriving is not taken as a reason to
  /// start again. Stopping resets the phone's USB connection and drops
  /// Bluetooth for a moment, and either would otherwise look exactly like a
  /// phone being connected.
  static const _autostartCooldown = Duration(seconds: 15);

  static const _usbPollInterval = Duration(seconds: 2);

  /// The one instance used by the whole app.
  static final AndroidAutoService instance = AndroidAutoService._();
  AndroidAutoService._();

  final _state = ValueStream<AndroidAutoState>(const AndroidAutoState());
  final _store = const AndroidAutoStore();
  final _hotspot = WifiHotspot();

  UsbPhoneFinder _usb = const UsbPhoneFinder();
  AndroidAutoWirelessNetwork _network =
      const AndroidAutoWirelessNetwork.hotspot();
  String _passphrase = '';
  bool _askedAboutAutostart = false;

  AndroidAutoController? _controller;
  AndroidAutoConnectionState _headUnit = AndroidAutoConnectionState.idle;

  // The session. [_session] goes up on every start and stop, so work left
  // over from an older session notices after each await and gives up.
  int _session = 0;
  bool _running = false;
  bool _automatic = false;
  bool _hadPhone = false;
  bool _startingHotspot = false;
  bool _wirelessOffered = false;
  bool _cableGraceOver = false;
  String? _wirelessPhone;
  AndroidAutoConnection? _connection;
  String? _problem;
  // Set while a cable-only session starts, see [startSession].
  bool _quietStart = false;
  String? _heldProblem;
  Timer? _idleTimer;
  Timer? _cableGraceTimer;

  // Starting on its own.
  Timer? _usbPoll;
  bool _polling = false;
  bool _usbPhonePresent = false;
  Set<String> _bluetoothConnected = {};
  DateTime? _cooldownUntil;

  String? _notificationBody;

  /// Everything worth showing about Android Auto right now.
  AndroidAutoState get state => _state.value;

  /// Emits every time [state] changes, starting with what it is now.
  Stream<AndroidAutoState> get changes => _state.stream;

  /// The head unit, or `null` where there is none.
  AndroidAutoController? get controller => _controller;

  /// Whether Android Auto works on this machine at all.
  bool get isSupported => _controller != null;

  /// Makes the head unit and starts watching for phones. Returns `false`
  /// where Android Auto cannot run, which leaves the extension adding
  /// nothing.
  Future<bool> start(AndroidAutoExtension config) async {
    // The real head unit is Linux, and android_auto runs a simulated phone on
    // macOS and Windows so the whole thing can be tried while developing.
    // There is no Android implementation yet.
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      SmartifyOsLog.info(
        _tag,
        'Android Auto is not available on ${Platform.operatingSystem}',
      );
      return false;
    }

    final about = SmartifyOsSettings.about;
    _network = config.wirelessNetwork;
    _usb = UsbPhoneFinder(extraVendorIds: config.extraPhoneVendorIds);
    final saved = await _store.load();
    _passphrase = saved.hotspotPassphrase;
    _askedAboutAutostart = saved.askedAboutAutostart;
    final wirelessAvailable = _network is! AndroidAutoNoNetwork;

    try {
      _controller = AndroidAutoController(
        config: AndroidAutoConfig(
          headUnitName: config.headUnitName ?? about.deviceName,
          carModel: config.carModel ?? about.model ?? 'SmartifyOS',
          carYear: config.carYear ?? '${SmartifyOsTime.now.year}',
          // Wireless is in here whether or not the driver has it switched
          // on, because this is what publishes the service on Bluetooth that
          // tells a phone being paired that this is a car it can project to
          // without a cable. Until a session offers it, phones that ask are
          // refused, which is what stops them asking.
          transports: {
            AndroidAutoTransport.usb,
            if (wirelessAvailable) AndroidAutoTransport.wireless,
          },
        ),
      );
    } catch (error, stackTrace) {
      SmartifyOsLog.error(
        _tag,
        'Could not create the head unit',
        error,
        stackTrace,
      );
      return false;
    }

    _state.value = AndroidAutoState(
      autostart: saved.autostart,
      wireless: saved.wireless,
      wirelessAvailable: wirelessAvailable,
      hotspotName: switch (_network) {
        AndroidAutoHotspotNetwork(:final name) => name ?? about.deviceName,
        _ => null,
      },
      wirelessPhones: saved.wirelessPhones,
    );

    // Both for as long as the car runs, like the head unit itself.
    _controller!.events.listen(_onHeadUnitEvent);
    _bluetoothConnected = {
      for (final device in Bluetooth.devices)
        if (device.connected) device.address,
    };
    BluetoothService.instance.readable.deviceChanges.listen(
      _onBluetoothDevices,
    );

    if (Platform.isLinux && _network is AndroidAutoHotspotNetwork) {
      // A hotspot still up from before a crash would keep the car off its own
      // Wi-Fi until the next session ended.
      unawaited(_hotspot.removeLeftover());
    }

    if (state.autostart) unawaited(_watchForPhones(checkNow: true));
    return true;
  }

  // ── Sessions ───────────────────────────────────────────────────────────────

  /// Starts looking for a phone, on the cable and over Bluetooth.
  ///
  /// [automatic] is for a start nobody asked for: it opens the window once a
  /// phone connects, only takes phones that have used Android Auto without a
  /// cable here before, and gives up again after [idleTimeout].
  Future<void> startSession({bool automatic = false}) async {
    final controller = _controller;
    if (controller == null || _running) return;

    final session = ++_session;
    _running = true;
    _automatic = automatic;
    _hadPhone = false;
    _wirelessOffered = false;
    _wirelessPhone = null;
    _connection = null;
    _problem = null;
    _cableGraceOver = false;
    SmartifyOsLog.info(_tag, automatic ? 'Starting on its own' : 'Starting');
    _publish();

    final cable = await _usb.isPhonePluggedIn();
    if (session != _session) return;
    final phone = cable ? null : _wirelessCandidate();
    if (phone != null) {
      // Before the start, which then offers Wi-Fi on the network made here.
      await _prepareWireless(phone);
      if (session != _session) return;
    }

    // Starting offers Wi-Fi as well, since the head unit was made able to.
    // Without a network made for this session there is nothing to offer, the
    // head unit reports that as an error, and it is taken back below. That
    // error is not something the driver should read about, so errors are
    // held while it starts, and dropped once the head unit says it is
    // looking for a phone, which it only does when the cable side started.
    _quietStart = !_wirelessOffered;
    await controller.start();
    if (session != _session) return;

    if (!_wirelessOffered) {
      await controller.stopWireless();
      // The head unit's events arrive a moment after the calls that caused
      // them.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (session != _session) return;
      _quietStart = false;
      final held = _heldProblem;
      _heldProblem = null;
      if (held != null) {
        SmartifyOsLog.warning(_tag, held);
        _problem = held;
      }
    }

    if (cable) {
      SmartifyOsLog.info(_tag, 'Found a phone on the cable');
      _cableGraceTimer = Timer(cableGrace, () {
        _cableGraceOver = true;
        unawaited(_tryWireless());
      });
    } else {
      _cableGraceOver = true;
    }
    _armIdleTimer();
    _publish();
  }

  /// Ends the session and takes the hotspot down, if there was one.
  Future<void> stopSession() async {
    final controller = _controller;
    if (controller == null || !_running) return;

    _session++;
    _running = false;
    _startingHotspot = false;
    _quietStart = false;
    _heldProblem = null;
    _idleTimer?.cancel();
    _cableGraceTimer?.cancel();
    _cooldownUntil = DateTime.now().add(_autostartCooldown);
    SmartifyOsLog.info(_tag, 'Stopping');
    // Straight away, so the notification goes as soon as Stop is pressed
    // rather than once the phone has said goodbye.
    _publish();

    await controller.stop();
    await _hotspot.takeDown();
    _wirelessOffered = false;
    _wirelessPhone = null;
    _connection = null;
    _publish();
  }

  /// Opens the Android Auto window, unless it is already open.
  void openWindow([BuildContext? context]) {
    if (AndroidAutoWindow.isOpen) return;
    final target = context ?? SmartifyOsNavigator.navigatorKey.currentContext;
    if (target == null) return;
    SmartifyOsNavigator.push(target, const AndroidAutoWindow());
  }

  /// A phone connected over Bluetooth that should be offered Android Auto
  /// without a cable, or `null`.
  ///
  /// A start nobody asked for only takes a phone that has done it here
  /// before, so a passenger's phone or an iPhone never brings the hotspot up
  /// on its own. A start the driver asked for takes any phone.
  BluetoothDevice? _wirelessCandidate() {
    // Only the real head unit has Wi-Fi to offer. The simulated phone on
    // macOS and Windows connects on its own.
    if (!Platform.isLinux || !state.usesWireless) return null;
    final connected = [
      for (final device in Bluetooth.devices)
        if (device.connected) device,
    ];
    for (final device in connected) {
      if (state.wirelessPhones.contains(device.address)) return device;
    }
    if (_automatic) return null;
    for (final device in connected) {
      if (device.kind == BluetoothDeviceKind.phone) return device;
    }
    return null;
  }

  /// Gets a Wi-Fi network ready for [phone] and tells the head unit about it.
  /// Does not start offering it: the caller does that, or `start` does.
  Future<bool> _prepareWireless(BluetoothDevice phone) async {
    final controller = _controller!;
    final session = _session;

    final AndroidAutoWirelessConfig config;
    switch (_network) {
      case AndroidAutoHotspotNetwork():
        _startingHotspot = true;
        _publish();
        final name = state.hotspotName!;
        final result = await _hotspot.bringUp(
          name: name,
          passphrase: _passphrase,
        );
        if (session != _session) {
          // Stopped while the hotspot was coming up.
          await _hotspot.takeDown();
          return false;
        }
        _startingHotspot = false;
        if (!result.ok) {
          SmartifyOsLog.warning(
            _tag,
            'Could not bring up the hotspot',
            result.error,
          );
          _problem = t.android_auto.problem_hotspot(reason: result.error!);
          _publish();
          return false;
        }
        config = AndroidAutoWirelessConfig(
          passphrase: _passphrase,
          ssid: name,
          interfaceName: result.interfaceName!,
          phoneAddress: phone.address,
        );
      case AndroidAutoExistingNetwork(
        :final passphrase,
        :final name,
        :final interfaceName,
      ):
        config = AndroidAutoWirelessConfig(
          passphrase: passphrase,
          ssid: name,
          interfaceName: interfaceName,
          phoneAddress: phone.address,
        );
      case AndroidAutoNoNetwork():
        return false;
    }

    controller.setWirelessConfig(config);
    _wirelessOffered = true;
    _wirelessPhone = phone.address;
    SmartifyOsLog.info(_tag, 'Offering Wi-Fi to ${phone.name}');
    _publish();
    return true;
  }

  /// Offers Android Auto without a cable to a phone on Bluetooth, if there is
  /// one and nothing better is going on.
  Future<void> _tryWireless() async {
    if (!_running ||
        _wirelessOffered ||
        _startingHotspot ||
        !_cableGraceOver ||
        _headUnit == AndroidAutoConnectionState.connected ||
        _headUnit == AndroidAutoConnectionState.handshaking) {
      return;
    }
    final phone = _wirelessCandidate();
    if (phone == null) return;

    final session = _session;
    if (!await _prepareWireless(phone)) return;
    if (session != _session) return;
    await _controller!.startWireless();
  }

  /// Ends a session nobody is using, see [idleTimeout].
  void _armIdleTimer() {
    _idleTimer?.cancel();
    if (!_running || _headUnit == AndroidAutoConnectionState.connected) return;
    if (!_automatic && !_hadPhone) return;
    _idleTimer = Timer(idleTimeout, () {
      if (!_running || _headUnit == AndroidAutoConnectionState.connected) {
        return;
      }
      SmartifyOsLog.info(
        _tag,
        'No phone for ${idleTimeout.inSeconds} s, stopping',
      );
      unawaited(stopSession());
    });
  }

  void _onHeadUnitEvent(AndroidAutoEvent event) {
    final previous = _headUnit;
    _headUnit = event.state;
    SmartifyOsLog.debug(
      _tag,
      'Head unit: ${event.state.name}'
      '${event.message == null ? '' : ', ${event.message}'}',
    );
    if (!_running) return;

    switch (event.state) {
      case AndroidAutoConnectionState.connected:
        _idleTimer?.cancel();
        _problem = null;
        if (previous != AndroidAutoConnectionState.connected) {
          unawaited(_onConnected());
        }
      case AndroidAutoConnectionState.error:
        final message = event.message;
        if (message != null && _quietStart) {
          _heldProblem = message;
        } else if (message != null) {
          _problem = message;
          SmartifyOsLog.warning(_tag, message);
        }
      case AndroidAutoConnectionState.searching when _quietStart:
        // The cable side is up, so whatever went wrong before this was the
        // Wi-Fi being offered with no network, see [startSession].
        _heldProblem = null;
      case AndroidAutoConnectionState.idle ||
          AndroidAutoConnectionState.searching ||
          AndroidAutoConnectionState.handshaking:
        if (previous == AndroidAutoConnectionState.connected) {
          SmartifyOsLog.info(_tag, 'The phone went away');
          _connection = null;
          _armIdleTimer();
          // A phone that dropped off the cable may well still be on
          // Bluetooth.
          unawaited(_tryWireless());
        }
    }
    _publish();
  }

  Future<void> _onConnected() async {
    final session = _session;
    // Wi-Fi only when it was offered and there is no phone on the cable,
    // since a cable plugged in takes over from Wi-Fi.
    final cable = !_wirelessOffered || await _usb.isPhonePluggedIn();
    if (session != _session ||
        _headUnit != AndroidAutoConnectionState.connected) {
      return;
    }

    _hadPhone = true;
    _connection = cable
        ? AndroidAutoConnection.cable
        : AndroidAutoConnection.wireless;
    SmartifyOsLog.info(
      _tag,
      'Phone connected ${cable ? 'with a cable' : 'over Wi-Fi'}',
    );
    final phone = _wirelessPhone;
    if (!cable && phone != null) _rememberWirelessPhone(phone);
    _publish();

    if (_automatic) openWindow();
    await _askAboutAutostart();
  }

  /// Asks once, the first time a phone connects, whether Android Auto should
  /// start on its own from now on. Few drivers would think to look in
  /// Settings for it.
  Future<void> _askAboutAutostart() async {
    if (_askedAboutAutostart || state.autostart) return;
    final context = SmartifyOsNavigator.navigatorKey.currentContext;
    if (context == null) return;

    _askedAboutAutostart = true;
    unawaited(_store.saveAskedAboutAutostart());
    final yes = await ThemedDialog.confirm(
      context,
      title: t.android_auto.autostart_question_title,
      message: t.android_auto.autostart_question_message,
      confirmLabel: t.android_auto.autostart_question_yes,
      cancelLabel: t.android_auto.autostart_question_no,
    );
    if (yes) await setAutostart(true);
  }

  // ── Starting on its own ────────────────────────────────────────────────────

  /// Starts watching the cable. With [checkNow], a phone already there when
  /// this is called starts a session too, which is what boot wants and a
  /// driver flipping the switch in Settings does not.
  Future<void> _watchForPhones({bool checkNow = false}) async {
    _usbPoll?.cancel();
    _usbPhonePresent = await _usb.isPhonePluggedIn();
    if (!state.autostart) return;

    if (checkNow && !_running) {
      if (_usbPhonePresent) {
        SmartifyOsLog.info(_tag, 'A phone is plugged in at boot');
        unawaited(startSession(automatic: true));
      } else if (_knownPhoneConnected(_bluetoothConnected)) {
        SmartifyOsLog.info(_tag, 'A known phone is on Bluetooth at boot');
        unawaited(startSession(automatic: true));
      }
    }

    // Reading a handful of small files every couple of seconds costs next to
    // nothing, and unlike a udev monitor it needs nothing installed.
    if (Platform.isLinux) {
      _usbPoll = Timer.periodic(_usbPollInterval, (_) => _pollUsb());
    }
  }

  void _stopWatching() {
    _usbPoll?.cancel();
    _usbPoll = null;
  }

  Future<void> _pollUsb() async {
    if (_polling) return;
    _polling = true;
    try {
      final present = await _usb.isPhonePluggedIn();
      final arrived = present && !_usbPhonePresent;
      _usbPhonePresent = present;
      if (arrived && _mayStartOnItsOwn) {
        SmartifyOsLog.info(_tag, 'A phone was plugged in');
        await startSession(automatic: true);
      }
    } finally {
      _polling = false;
    }
  }

  void _onBluetoothDevices(List<BluetoothDevice> devices) {
    final connected = {
      for (final device in devices)
        if (device.connected) device.address,
    };
    final arrived = connected.difference(_bluetoothConnected);
    _bluetoothConnected = connected;
    if (arrived.isEmpty) return;

    if (_running) {
      unawaited(_tryWireless());
    } else if (state.usesWireless &&
        _mayStartOnItsOwn &&
        _knownPhoneConnected(arrived)) {
      SmartifyOsLog.info(_tag, 'A known phone connected over Bluetooth');
      unawaited(startSession(automatic: true));
    }
  }

  bool get _mayStartOnItsOwn {
    if (_running || !state.autostart) return false;
    final until = _cooldownUntil;
    return until == null || DateTime.now().isAfter(until);
  }

  bool _knownPhoneConnected(Set<String> addresses) =>
      state.usesWireless && addresses.any(state.wirelessPhones.contains);

  // ── The driver's choices ───────────────────────────────────────────────────

  /// Whether Android Auto starts by itself.
  Future<void> setAutostart(bool on) async {
    if (on == state.autostart) return;
    _state.value = state.copyWith(autostart: on);
    await _store.saveAutostart(on);
    if (on) {
      // Switched on by hand, so there is nothing left to ask.
      _askedAboutAutostart = true;
      unawaited(_store.saveAskedAboutAutostart());
      await _watchForPhones();
    } else {
      _stopWatching();
    }
  }

  /// Whether Android Auto may connect without a cable.
  ///
  /// Switching it off leaves a phone that is projecting over Wi-Fi alone: a
  /// driver who does that mid journey means "not next time", not "cut me off
  /// now".
  Future<void> setWireless(bool on) async {
    if (on == state.wireless) return;
    _state.value = state.copyWith(wireless: on);
    await _store.saveWireless(on);
    if (!_running) return;
    if (on) {
      unawaited(_tryWireless());
    } else if (_wirelessOffered &&
        _connection != AndroidAutoConnection.wireless) {
      await _controller?.stopWireless();
      await _hotspot.takeDown();
      _wirelessOffered = false;
      _wirelessPhone = null;
      _publish();
    }
  }

  /// Forgets every phone that starts Android Auto over Bluetooth.
  Future<void> forgetWirelessPhones() async {
    _state.value = state.copyWith(wirelessPhones: const {});
    await _store.saveWirelessPhones(const {});
  }

  void _rememberWirelessPhone(String address) {
    if (state.wirelessPhones.contains(address)) return;
    final phones = {...state.wirelessPhones, address};
    _state.value = state.copyWith(wirelessPhones: phones);
    unawaited(_store.saveWirelessPhones(phones));
  }

  // ── What the driver sees ───────────────────────────────────────────────────

  void _publish() {
    final AndroidAutoPhase phase;
    if (!_running) {
      phase = AndroidAutoPhase.stopped;
    } else if (_startingHotspot) {
      phase = AndroidAutoPhase.startingHotspot;
    } else {
      phase = switch (_headUnit) {
        AndroidAutoConnectionState.connected => AndroidAutoPhase.connected,
        AndroidAutoConnectionState.handshaking => AndroidAutoPhase.connecting,
        _ => AndroidAutoPhase.waitingForPhone,
      };
    }
    _state.value = state.copyWith(
      phase: phase,
      connection: phase == AndroidAutoPhase.connected ? _connection : null,
      problem: _problem,
    );
    _syncNotification();
  }

  /// Keeps the ongoing notification, and with it the icon at the end of the
  /// status bar, in step with the session. Only shown again when its text
  /// changes, since showing it moves it to the top of the shade.
  void _syncNotification() {
    if (!state.isRunning) {
      if (_notificationBody == null) return;
      _notificationBody = null;
      SmartifyOsNotifications.dismissNotification(notificationId);
      return;
    }

    final body = androidAutoStatusText(state);
    if (body == _notificationBody) return;
    _notificationBody = body;
    SmartifyOsNotifications.showNotification(
      SmartifyOsNotification(
        id: notificationId,
        title: t.android_auto.title,
        body: body,
        icon: const AndroidAutoIcon(),
        ongoing: true,
        onTap: openWindow,
        actions: [
          NotificationAction(
            label: t.android_auto.stop,
            icon: const Icon(Icons.stop),
            onTap: (_) => unawaited(stopSession()),
          ),
        ],
      ),
    );
  }
}
