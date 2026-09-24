import 'package:android_auto/android_auto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartify_os_android_auto/src/i18n/strings.g.dart';
import 'package:smartify_os_android_auto/src/providers/android_auto_provider.dart';
import 'package:smartify_os_android_auto/src/services/android_auto/android_auto_service.dart';
import 'package:smartify_os_android_auto/src/widgets/android_auto_icon.dart';
import 'package:smartify_os_core/media.dart';

/// What the phone is playing through Android Auto, on the home screen.
///
/// The same card as the Bluetooth player, with the cover, and only the
/// buttons Android Auto has keys for: play and pause, next and previous. It
/// has no way to shuffle, repeat or scrub.
///
/// Internal: the `AndroidAutoIds.playerWidget` card.
class AndroidAutoPlayerHomeWidget extends ConsumerWidget {
  const AndroidAutoPlayerHomeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = AndroidAutoService.instance;
    final info =
        ref.watch(androidAutoNowPlayingProvider).value ?? service.nowPlaying;
    final controller = service.controller;
    if (info == null || controller == null) return const SizedBox.shrink();

    return MediaPlayerCard(
      info: info,
      controls: MediaPlayerControls(
        onPlayPause: () => controller.pressKey(AndroidAutoKey.playPause),
        onNext: () => controller.pressKey(AndroidAutoKey.next),
        onPrevious: () => controller.pressKey(AndroidAutoKey.previous),
      ),
      sourceIcon: const AndroidAutoIcon(),
      // The app playing it, which is more use than "Android Auto" when there
      // is one to name.
      sourceName: controller.lastMediaInfo?.source ?? t.android_auto.title,
    );
  }
}
