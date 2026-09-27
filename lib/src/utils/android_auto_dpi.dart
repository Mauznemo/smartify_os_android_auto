import 'dart:math';
import 'dart:ui' show Size;

/// Internal: the density to tell the phone, so that Android Auto's text and
/// buttons come out [sizePercent] percent of the size of SmartifyOS's own.
///
/// A phone lays its interface out in density independent pixels, 160 of them
/// to the inch at the density it is told. SmartifyOS lays itself out on a
/// canvas scaled to the screen, and [pixelRatio] is how many screen pixels one
/// canvas pixel is worth there (what `MediaQuery` says inside it). Telling the
/// phone 160 times that makes one of its pixels one of SmartifyOS's, whatever
/// the screen's resolution, so the resolution only decides how sharp the
/// picture is and never how big anything on it is.
///
/// [physicalViewSize] is the Android Auto view in screen pixels, if known. The
/// largest frame the head unit asks the phone for is 1920x1080, and a view
/// larger than that gets a smaller picture stretched to fill it, so the phone
/// is told a density that much lower to make up for the stretch.
int androidAutoDpi({
  required double pixelRatio,
  required int sizePercent,
  Size? physicalViewSize,
}) {
  var stretch = 1.0;
  if (physicalViewSize != null && !physicalViewSize.isEmpty) {
    stretch = min(
      1.0,
      min(1920 / physicalViewSize.width, 1080 / physicalViewSize.height),
    );
  }
  final dpi = 160 * pixelRatio * stretch * sizePercent / 100;
  // Anything outside this is a measurement gone wrong, not a car screen.
  return dpi.round().clamp(60, 640);
}
