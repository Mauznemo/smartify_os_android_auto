import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:android_auto/android_auto.dart';
import 'package:flutter/foundation.dart' show listEquals;
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
import 'package:smartify_os_core/gps.dart';
import 'package:smartify_os_core/media.dart';
import 'package:smartify_os_core/modals.dart';
import 'package:smartify_os_core/night_mode.dart';
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

  /// How long a phone that was projecting gets to come back after the cable
  /// comes out or the Wi-Fi drops, before Android Auto stops by itself. The
  /// head unit gets a phone on the cable back in about five seconds when it
  /// can, and one on Wi-Fi as soon as the phone dials in again.
  static const lostPhoneTimeout = Duration(seconds: 30);

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

  /// How often the phone is given the car's position. It expects a reading
  /// about this often, as a receiver would give it, and goes back to its own
  /// GPS within seconds when they stop.
  static const _positionInterval = Duration(seconds: 1);

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
  Size? _viewSize;
  bool _offersCarGps = false;
  // The car's position as last handed to the phone, so one that stops
  // changing (a fake one, or a source that only reports now and then) is
  // repeated rather than left to go stale, and whether a reading came in
  // since the last repeat, in which case it needs none.
  AndroidAutoLocation? _position;
  bool _positionFresh = false;

  AndroidAutoController? _controller;
  AndroidAutoConnectionState _headUnit = AndroidAutoConnectionState.idle;

  // The session. [_session] goes up on every start and stop, so work left
  // over from an older session notices after each await and gives up.
  int _session = 0;
  bool _running = false;
  bool _automatic = false;
  bool _hadPhone = false;
  // The controller's hasVideo, as last seen, so the moment it turns true is
  // noticed once.
  bool _video = false;
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

  // What the phone is doing, for the home screen. See [_onMedia].
  final _nowPlaying = ValueStream<MediaPlayerInfo?>(null);
  final _navigation = ValueStream<AndroidAutoNavigation?>(null);
  AndroidAutoMediaInfo? _media;
  DateTime? _mediaPositionAt;
  Uint8List? _artworkBytes;
  ImageProvider? _artwork;

  /// Everything worth showing about Android Auto right now.
  AndroidAutoState get state => _state.value;

  /// Emits every time [state] changes, starting with what it is now.
  Stream<AndroidAutoState> get changes => _state.stream;

  /// The head unit, or `null` where there is none.
  AndroidAutoController? get controller => _controller;

  /// What the phone is playing, while one is connected and playing anything.
  MediaPlayerInfo? get nowPlaying => _nowPlaying.value;

  /// Emits every time [nowPlaying] changes, starting with what it is now.
  Stream<MediaPlayerInfo?> get nowPlayingChanges => _nowPlaying.stream;

  /// The guidance in progress, while a connected phone is guiding.
  AndroidAutoNavigation? get navigation => _navigation.value;

  /// Emits every time [navigation] changes, starting with what it is now.
  Stream<AndroidAutoNavigation?> get navigationChanges => _navigation.stream;

  /// Whether Android Auto works on this machine at all.
  bool get isSupported => _controller != null;

  /// Whether the phone is being given the car's position in this run.
  ///
  /// The head unit tells the phone which sensors the car has once, when it is
  /// made at boot, so switching [AndroidAutoState.useCarGps] only takes
  /// effect the next time SmartifyOS starts. Until then the two differ.
  bool get offersCarGps => _offersCarGps;

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
    _viewSize = saved.viewSize;
    _offersCarGps = saved.useCarGps;
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
          sensors: {
            AndroidAutoSensor.nightMode,
            AndroidAutoSensor.drivingStatus,
            // Only when the driver asked for it: the phone stops using its own
            // position the moment the car offers one.
            if (_offersCarGps) AndroidAutoSensor.location,
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
      showPlayer: saved.showPlayer,
      showNavigation: saved.showNavigation,
      useCarGps: saved.useCarGps,
    );

    // Both for as long as the car runs, like the head unit itself.
    _controller!.events.listen(_onHeadUnitEvent);
    // Whether the phone's picture is live changes on a notification rather
    // than an event, since the head unit only knows once it has asked.
    _controller!.addListener(_onControllerChanged);
    _controller!.mediaPlayback.listen(_onMedia);
    _controller!.navigation.listen(_onNavigation);
    // What the car knows, handed on as it changes. The head unit keeps the
    // latest of each and gives it to every phone that connects.
    SmartifyOsNightMode.nightModeChanges.listen(_onNightMode);
    if (_offersCarGps) {
      SmartifyOsLog.info(_tag, "Giving the phone the car's GPS position");
      SmartifyOsGps.fixes.listen(_onGpsFix);
      Timer.periodic(_positionInterval, (_) => _repeatPosition());
    }
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
    // The phone is asked for its frame, shape and all, the moment it connects,
    // and keeps it for the whole connection. A start with the window closed
    // (starting on its own, or from a button of the car's) has no view to
    // measure, so it is told what the view measured last time. Without that
    // the phone draws a 16:9 picture that sits letterboxed until the window
    // opens, and then lays out again, dropping the picture for a moment.
    final viewSize = _viewSize;
    if (!AndroidAutoWindow.isOpen && viewSize != null) {
      controller.setViewSize(viewSize);
    }
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
    _forgetPhoneState();
    _publish();
  }

  /// Opens the Android Auto window, unless it is already open.
  void openWindow([BuildContext? context]) {
    if (AndroidAutoWindow.isOpen) return;
    final target = context ?? SmartifyOsNavigator.navigatorKey.currentContext;
    if (target == null) return;
    SmartifyOsNavigator.push(target, const AndroidAutoWindow());
  }

  /// Notes how big, in physical pixels, the window's view is, so a start with
  /// the window closed can tell the phone. Called by the window whenever it is
  /// laid out; the car's screen never changes, so this is almost always the
  /// same number, and only a different one is saved.
  void rememberViewSize(Size physicalSize) {
    if (physicalSize == _viewSize) return;
    _viewSize = physicalSize;
    unawaited(_store.saveViewSize(physicalSize));
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

  /// Ends a session nobody is using: one whose phone went away and did not
  /// come back within [lostPhoneTimeout], or one that started on its own and
  /// found no phone within [idleTimeout].
  void _armIdleTimer() {
    _idleTimer?.cancel();
    if (!_running || _headUnit == AndroidAutoConnectionState.connected) return;
    if (!_automatic && !_hadPhone) return;
    final lost = _hadPhone;
    final timeout = lost ? lostPhoneTimeout : idleTimeout;
    _idleTimer = Timer(timeout, () {
      if (!_running || _headUnit == AndroidAutoConnectionState.connected) {
        return;
      }
      SmartifyOsLog.info(_tag, 'No phone for ${timeout.inSeconds} s, stopping');
      // Said where the driver will look, so a window that suddenly says
      // "not running" explains itself.
      if (lost) _problem = t.android_auto.problem_phone_lost;
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
          // In case the phone spoke up a moment before it counted as
          // connected.
          _publishPhoneState();
        }
      case AndroidAutoConnectionState.error:
        final message = event.message;
        if (message != null && _quietStart) {
          _heldProblem = message;
        } else if (message != null) {
          _problem = message;
          SmartifyOsLog.warning(_tag, message);
        }
        if (previous == AndroidAutoConnectionState.connected) _onPhoneLost();
      case AndroidAutoConnectionState.searching when _quietStart:
        // The cable side is up, so whatever went wrong before this was the
        // Wi-Fi being offered with no network, see [startSession].
        _heldProblem = null;
      case AndroidAutoConnectionState.idle ||
          AndroidAutoConnectionState.searching ||
          AndroidAutoConnectionState.handshaking:
        if (previous == AndroidAutoConnectionState.connected) _onPhoneLost();
    }
    _publish();
  }

  /// The connection to a phone ended while the session carries on, and the
  /// head unit is trying to get it back.
  void _onPhoneLost() {
    SmartifyOsLog.info(_tag, 'The phone went away');
    _connection = null;
    // Whatever it was playing or guiding towards is not true any more, and a
    // turn left on screen after the phone has gone is the one thing a head
    // unit must never show.
    _forgetPhoneState();
    _armIdleTimer();
    // A phone that dropped off the cable may well still be on Bluetooth.
    unawaited(_tryWireless());
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

    // Already now rather than once the picture is there, so the driver sees
    // Android Auto starting instead of wondering whether anything happened.
    if (_automatic) openWindow();
  }

  /// Follows the controller's [AndroidAutoController.hasVideo], which is what
  /// tells "the phone agreed to project" (connected, a good twenty seconds
  /// early over Wi-Fi) apart from "its picture is on screen".
  void _onControllerChanged() {
    final live = _controller!.hasVideo;
    if (live == _video) return;
    _video = live;
    if (!_running) return;
    if (live) unawaited(_onPicture());
    _publish();
  }

  /// The phone's picture is on screen: from here Android Auto visibly works.
  Future<void> _onPicture() async {
    SmartifyOsLog.info(_tag, 'The phone is projecting');
    await _askAboutAutostart();
  }

  /// Asks once, the first time a phone projects, whether Android Auto should
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

  // ── What the phone is doing ────────────────────────────────────────────────

  bool get _phoneConnected =>
      _running && _headUnit == AndroidAutoConnectionState.connected;

  /// A new track, or news about the one playing.
  ///
  /// The phone says where playback is only when that changes (a new song, a
  /// pause, a skip), and expects the head unit to count on by itself in
  /// between. So the moment is noted only when the position or whether it
  /// plays actually changed: news of something else (the cover arriving)
  /// must not reset the count to a position that is seconds old by now.
  void _onMedia(AndroidAutoMediaInfo media) {
    final previous = _media;
    _media = media;
    if (previous == null ||
        media.position != previous.position ||
        media.state != previous.state ||
        media.song != previous.song) {
      _mediaPositionAt = DateTime.now();
    }

    // A new MemoryImage is a new decode, so only make one for a new cover.
    // The same cover arrives again with every update, as new bytes.
    final art = media.albumArt;
    if (art == null) {
      _artworkBytes = null;
      _artwork = null;
    } else if (!listEquals(art, _artworkBytes)) {
      _artworkBytes = art;
      _artwork = MemoryImage(art);
    }
    _publishPhoneState();
  }

  void _onNightMode(bool night) {
    SmartifyOsLog.info(
      _tag,
      'Telling the phone it is ${night ? 'night' : 'day'}',
    );
    _controller?.setNightMode(night);
  }

  /// A fix that no longer says where the car is stops the repeating, so the
  /// phone goes back to its own GPS rather than being told an old position.
  void _onGpsFix(GpsFix? fix) {
    if (fix == null || !fix.hasPosition) {
      _position = null;
      return;
    }
    _position = AndroidAutoLocation(
      latitude: fix.latitude!,
      longitude: fix.longitude!,
      accuracyMetres: fix.accuracy,
      altitudeMetres: fix.altitude,
      speedMps: fix.speed,
      bearingDegrees: fix.heading,
    );
    _positionFresh = true;
    _controller?.setLocation(_position!);
  }

  void _repeatPosition() {
    if (_positionFresh) {
      _positionFresh = false;
      return;
    }
    final position = _position;
    if (position != null) _controller?.setLocation(position);
  }

  void _onNavigation(AndroidAutoNavigation navigation) {
    _navigation.forceSet(
      _phoneConnected && navigation.isGuiding ? navigation : null,
    );
  }

  void _publishPhoneState() {
    final media = _media;
    if (!_phoneConnected ||
        media == null ||
        (media.isEmpty && media.state != AndroidAutoPlaybackState.playing)) {
      _nowPlaying.value = null;
      return;
    }
    _nowPlaying.value = MediaPlayerInfo(
      title: media.song,
      artist: media.artist,
      album: media.album,
      artwork: _artwork,
      isPlaying: media.isPlaying,
      duration: media.duration,
      position: media.position,
      positionReportedAt: media.position == null ? null : _mediaPositionAt,
    );
  }

  void _forgetPhoneState() {
    _media = null;
    _mediaPositionAt = null;
    _artworkBytes = null;
    _artwork = null;
    _nowPlaying.value = null;
    _navigation.value = null;
  }

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

  /// Whether what the phone is playing gets a card on the home screen.
  Future<void> setShowPlayer(bool on) async {
    if (on == state.showPlayer) return;
    _state.value = state.copyWith(showPlayer: on);
    await _store.saveShowPlayer(on);
  }

  /// Whether the phone's directions get a card on the home screen.
  Future<void> setShowNavigation(bool on) async {
    if (on == state.showNavigation) return;
    _state.value = state.copyWith(showNavigation: on);
    await _store.saveShowNavigation(on);
  }

  /// Whether the phone is told where the car is from the car's own GPS.
  /// Takes effect the next time SmartifyOS starts, see [offersCarGps].
  Future<void> setUseCarGps(bool on) async {
    if (on == state.useCarGps) return;
    _state.value = state.copyWith(useCarGps: on);
    await _store.saveUseCarGps(on);
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
        AndroidAutoConnectionState.connected when _video =>
          AndroidAutoPhase.connected,
        AndroidAutoConnectionState.connected =>
          AndroidAutoPhase.startingOnPhone,
        AndroidAutoConnectionState.handshaking => AndroidAutoPhase.connecting,
        _ when _hadPhone => AndroidAutoPhase.reconnecting,
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
