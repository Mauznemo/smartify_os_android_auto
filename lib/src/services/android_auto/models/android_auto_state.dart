import 'package:freezed_annotation/freezed_annotation.dart';

part 'android_auto_state.freezed.dart';

/// How far Android Auto has got.
enum AndroidAutoPhase {
  /// Not running. Nothing is projected and no phone is looked for.
  stopped,

  /// Running, and looking for a phone: on the cable, and over Wi-Fi once a
  /// phone is connected over Bluetooth.
  waitingForPhone,

  /// Bringing up the Wi-Fi hotspot a phone without a cable joins.
  startingHotspot,

  /// A phone was found and the two are agreeing how to talk.
  connecting,

  /// The phone has agreed and is starting Android Auto, but has not sent a
  /// picture yet. Over Wi-Fi this can take a good twenty seconds.
  startingOnPhone,

  /// The phone is projecting, and its picture is on screen.
  connected,

  /// The phone that was projecting went away (the cable came out, or the
  /// Wi-Fi dropped), and it is being waited for. Android Auto stops by itself
  /// if it does not come back.
  reconnecting,
}

/// How the phone is connected, once it is.
enum AndroidAutoConnection {
  /// With a USB cable.
  cable,

  /// Over Wi-Fi, after agreeing the details over Bluetooth.
  wireless,
}

/// Everything about Android Auto worth showing: whether it is running, how
/// the phone is connected, and the driver's own choices about it.
///
/// Watch `androidAutoStateProvider` to follow it, or read
/// `SmartifyOsAndroidAuto.state` once.
@freezed
abstract class AndroidAutoState with _$AndroidAutoState {
  const AndroidAutoState._();

  const factory AndroidAutoState({
    @Default(AndroidAutoPhase.stopped) AndroidAutoPhase phase,

    /// How the phone is connected. Only set while [phase] is
    /// [AndroidAutoPhase.connected].
    AndroidAutoConnection? connection,

    /// The last thing that went wrong, in words, or `null`. Cleared when the
    /// next session starts. Worth showing wherever the driver would otherwise
    /// wonder why nothing is happening.
    String? problem,

    /// Whether Android Auto starts by itself when a phone is plugged in, or a
    /// phone it knows connects over Bluetooth.
    @Default(false) bool autostart,

    /// Whether the driver allows Android Auto without a cable. Only matters
    /// when [wirelessAvailable].
    @Default(true) bool wireless,

    /// Whether this car can do Android Auto without a cable at all, that is
    /// whether it was set up with a Wi-Fi network for the phone.
    @Default(false) bool wirelessAvailable,

    /// The name of the Wi-Fi hotspot the car brings up for the phone, or
    /// `null` when it does not bring one up.
    String? hotspotName,

    /// The Bluetooth addresses of the phones that start Android Auto on their
    /// own when they connect: every phone that has used it here without a
    /// cable.
    @Default(<String>{}) Set<String> wirelessPhones,

    /// Whether what the phone is playing gets a card on the home screen,
    /// standing in for the Bluetooth one.
    @Default(true) bool showPlayer,

    /// Whether the phone's turn by turn directions get a card on the home
    /// screen while it guides.
    @Default(true) bool showNavigation,

    /// Whether the phone is told where the car is from the car's own GPS,
    /// rather than using its own. Off unless the driver turns it on, since a
    /// phone's receiver is usually the better one.
    @Default(false) bool useCarGps,
  }) = _AndroidAutoState;

  /// Whether Android Auto is running, whatever it is doing.
  bool get isRunning => phase != AndroidAutoPhase.stopped;

  /// Whether a phone is projecting right now, with its picture on screen.
  bool get isConnected => phase == AndroidAutoPhase.connected;

  /// Whether a phone connected over Bluetooth is looked for, too.
  bool get usesWireless => wirelessAvailable && wireless;
}
