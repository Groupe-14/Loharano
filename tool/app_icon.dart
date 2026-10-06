import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const sizes = [192, 512];
  for (final size in sizes) {
    final regular = _mark(size, inset: 0);
    final maskable = _mark(size, inset: (size * 0.16).round());
    File('web/icons/Icon-$size.png').writeAsBytesSync(img.encodePng(regular));
    File('web/icons/Icon-maskable-$size.png')
        .writeAsBytesSync(img.encodePng(maskable));
    if (size == 192) {
      File('web/favicon.png').writeAsBytesSync(img.encodePng(regular));
    }
  }
}

img.Image _mark(int size, {required int inset}) {
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(0x0F, 0x5C, 0x56));
  final canvas = size - inset * 2;
  final cx = inset + canvas ~/ 2;
  final radius = (canvas * 0.22).round();
  final paper = img.ColorRgb8(0xF3, 0xEF, 0xE6);
  img.fillCircle(
    image,
    x: cx,
    y: inset + (canvas * 0.40).round(),
    radius: radius,
    color: paper,
  );
  img.fillCircle(
    image,
    x: cx,
    y: inset + (canvas * 0.58).round(),
    radius: (radius * 0.72).round(),
    color: paper,
  );
  return image;
}
