import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Android Auto logo, drawn like an [Icon]: in the colour and size of the
/// surrounding [IconTheme] unless you give it your own.
///
/// It is what the app list, the notification and the status bar show, and
/// fits anywhere an `Icon` does:
///
/// ```dart
/// SmartifyOsNotification(title: 'Android Auto', icon: const AndroidAutoIcon())
/// ```
class AndroidAutoIcon extends StatelessWidget {
  /// The logo from Material Design Icons (`mdi:android-auto`), which is
  /// Apache 2.0 licensed. Embedded rather than pulled in with an icon font
  /// package, since this is the only icon needed.
  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="M22.78 17.91c.16.25.22.51.22.79 0 .38-.13.69-.43.94s-.63.36'
      '-1.01.36h-2.48L12.42 8h-.84L4.92 20H2.39c-.47 0-.86-.2-1.17-.62-.31-.42'
      '-.33-.88-.05-1.38l9.61-16.31C11.09 1.22 11.5 1 12 1c.53 0 .92.22 1.17'
      '.69l9.61 16.22m-18 4.4L12 9.38l7.22 12.93-.72.69-6.5-2.66L5.44 23l-.66'
      '-.69z"/></svg>';

  final double? size;
  final Color? color;

  const AndroidAutoIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = this.size ?? theme.size ?? 24;
    final color = this.color ?? theme.color;

    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
