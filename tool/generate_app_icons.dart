// Run from the repository root: dart run tool/generate_app_icons.dart
// Encode the supplied artwork at platform sizes without redrawing it.
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final foreground = img.decodePng(
    File('docs/assets/icon-foreground.png').readAsBytesSync(),
  )!;
  final background = img.decodePng(
    File('docs/assets/icon.png').readAsBytesSync(),
  )!;
  if (foreground.width != foreground.height ||
      background.width != background.height) {
    throw StateError('Icon sources must be square');
  }
  final frames = [16, 24, 32, 48, 64, 128, 256]
      .map(
        (size) => img.copyResize(
          foreground,
          width: size,
          height: size,
          interpolation: img.Interpolation.average,
        ),
      )
      .toList();
  File('windows/runner/resources/app_icon.ico')
      .writeAsBytesSync(img.IcoEncoder().encodeImages(frames));
  const densities = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  for (final entry in densities.entries) {
    final icon = img.copyResize(
      background,
      width: entry.value,
      height: entry.value,
      interpolation: img.Interpolation.average,
    );
    File('android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png')
        .writeAsBytesSync(img.encodePng(icon));
  }
  stdout.writeln(
    'Generated 7 Windows ICO frames and 5 Android launcher sizes.',
  );
}
