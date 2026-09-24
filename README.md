# smartify_os_android_auto

Android Auto for [SmartifyOS](https://github.com/Mauznemo/smartify_os_flutter_test):
plug a phone in, or connect it over Bluetooth, and it projects. Built on the
[`android_auto`](https://pub.dev/packages/android_auto) Flutter plugin.

```dart
await SmartifyOs().init(
  bluetooth: const BluetoothConfig(name: 'Miata'),
  settings: SettingsConfig(about: const AboutConfig(deviceName: 'Miata')),
  extensions: [
    const AndroidAutoExtension(),
  ],
);
```

## What it adds

- **Android Auto in the app list.** It opens full screen and starts looking for a phone.
  Closing the window leaves Android Auto running.
- **A notification while it runs**, with the Android Auto icon at the end of the status
  bar and a Stop button. Tapping it brings the window back.
- **A page in Settings**, under Connectivity: start and stop, whether it starts on its
  own, whether it may connect without a cable, and which phones start it over Bluetooth.
- The first time a phone connects, it asks whether Android Auto should start on its own
  from then on.
- **Two cards on the home screen** while a phone is connected, each of which can be
  switched off in Settings:
  - what it is playing, with the cover, in place of the Bluetooth player (the phone
    reports the same song over Bluetooth too). Play, pause, next and previous are the
    keys Android Auto has, so those are the buttons;
  - the next turn while it is guiding: the arrow, how far, onto which road, the lanes,
    and when you get there.

  They come from what the phone says rather than from its picture, so they work with
  the Android Auto window closed. `SmartifyOsAndroidAuto.nowPlaying` and `.navigation`,
  and the providers next to them, are the same data for a screen of your own.

## How a phone connects

1. **A phone on the cable** projects over the cable.
2. Otherwise **a phone connected over Bluetooth** gets a Wi-Fi hotspot brought up for it
   and projects without a cable. The hotspot goes down again when Android Auto stops.
3. Otherwise it waits: plugging a phone in, or a phone connecting over Bluetooth, carries
   on from 1 or 2.

When it **starts on its own**, it does so once at boot if a phone is already plugged in,
and afterwards whenever one is plugged in, or whenever a phone that has used Android Auto
without a cable here connects over Bluetooth. Other phones on Bluetooth (a passenger's,
an iPhone) never bring the hotspot up by themselves. A session that started on its own and
finds no phone within a minute stops again.

**Pair phones after installing this.** The car tells phones it can do Android Auto without
a cable from the moment it boots, whether or not Android Auto is running, but a phone only
reads that while it pairs. One paired before this was installed has to be forgotten and
paired again once.

See `AndroidAutoWirelessNetwork` for a car that is always on a network the phone can join
too, or that should only ever use the cable.

## What the car needs

Everything the `android_auto` plugin lists for Linux (its build dependencies, and the udev
rule that lets a normal user open a phone), plus NetworkManager (`nmcli`) and `iw` for the
hotspot, and passwordless `sudo` for bringing it up. The SmartifyOS install script sets all
of that up.

It runs the real head unit on Linux, and the plugin's pretend phone on macOS and Windows,
so the whole flow can be tried while developing. It adds nothing on Android yet, since the
plugin has no Android implementation.

## Working on it

This package only says which SmartifyOS versions it works with, not where to get one (see
`EXTENSIONS.md` in the SmartifyOS repository), so on its own it needs a
`pubspec_overrides.yaml`:

```bash
cp pubspec_overrides.example.yaml pubspec_overrides.yaml
flutter pub get
dart run slang                 # after changing lib/src/i18n/en.i18n.json
dart run build_runner build    # after changing a freezed class or a provider
flutter analyze && flutter test
```

## Licence

GPL-3.0-or-later, see `LICENSE`. The `android_auto` plugin links aasdk, which is GPL, so
this package is GPL too, and so is any car's app that uses it.
