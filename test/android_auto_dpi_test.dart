import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_os_android_auto/src/utils/android_auto_dpi.dart';

/// Android Auto's text and buttons follow SmartifyOS's size, not the screen's
/// resolution: the same canvas on a sharper screen gets a higher density, so
/// the phone draws the same layout with more pixels.
void main() {
  test('one Android Auto pixel is one SmartifyOS pixel at 100%', () {
    // 1024 wide screen, 1080 wide canvas.
    expect(androidAutoDpi(pixelRatio: 1024 / 1080, sizePercent: 100), 152);
    // Twice the resolution, the same size on screen.
    expect(androidAutoDpi(pixelRatio: 2048 / 1080, sizePercent: 100), 303);
  });

  test('the driver picks a size relative to that', () {
    expect(androidAutoDpi(pixelRatio: 1, sizePercent: 125), 200);
    expect(androidAutoDpi(pixelRatio: 1, sizePercent: 70), 112);
  });

  test('a view larger than the biggest frame makes up for the stretch', () {
    // The phone draws in 1920 wide and it is stretched to 2560.
    expect(
      androidAutoDpi(
        pixelRatio: 2,
        sizePercent: 100,
        physicalViewSize: const Size(2560, 1000),
      ),
      240,
    );
    // One that fits is drawn one to one.
    expect(
      androidAutoDpi(
        pixelRatio: 1,
        sizePercent: 100,
        physicalViewSize: const Size(1024, 550),
      ),
      160,
    );
  });

  test('a measurement gone wrong never reaches the phone', () {
    expect(androidAutoDpi(pixelRatio: 0, sizePercent: 100), 60);
    expect(androidAutoDpi(pixelRatio: 50, sizePercent: 100), 640);
  });
}
