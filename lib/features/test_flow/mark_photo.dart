import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Heuristique de cadrage, pas un seuil sanitaire.
/// Une marque noire sous un gobelet clair reste plus sombre que le pourtour.
class MarkRead {
  const MarkRead(
      {required this.sharpEnough,
      required this.markVisible,
      required this.contrast});

  final bool sharpEnough;
  final bool? markVisible;
  final double contrast;
}

MarkRead readMark(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const MarkRead(sharpEnough: false, markVisible: null, contrast: 0);
  }
  final image = img.copyResize(decoded, width: 160);
  final sharpness = _laplacianVariance(image);
  if (sharpness < 18) {
    return MarkRead(sharpEnough: false, markVisible: null, contrast: 0);
  }
  final center = _meanLuminance(image, 0.42, 0.58);
  final border = _meanLuminance(image, 0.12, 0.28);
  final contrast = border - center;
  if (contrast > 18) {
    return MarkRead(sharpEnough: true, markVisible: true, contrast: contrast);
  }
  if (contrast < 6) {
    return MarkRead(sharpEnough: true, markVisible: false, contrast: contrast);
  }
  return MarkRead(sharpEnough: true, markVisible: null, contrast: contrast);
}

double _meanLuminance(img.Image image, double start, double end) {
  final x0 = (image.width * start).floor();
  final x1 = (image.width * end).floor();
  final y0 = (image.height * start).floor();
  final y1 = (image.height * end).floor();
  var sum = 0.0;
  var count = 0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final pixel = image.getPixel(x, y);
      sum += 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
      count += 1;
    }
  }
  return count == 0 ? 0 : sum / count;
}

double _laplacianVariance(img.Image image) {
  final values = <double>[];
  for (var y = 1; y < image.height - 1; y += 2) {
    for (var x = 1; x < image.width - 1; x += 2) {
      final center = _luma(image, x, y);
      final lap = _luma(image, x, y - 1) +
          _luma(image, x, y + 1) +
          _luma(image, x - 1, y) +
          _luma(image, x + 1, y) -
          4 * center;
      values.add(lap);
    }
  }
  if (values.isEmpty) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  var variance = 0.0;
  for (final value in values) {
    variance += (value - mean) * (value - mean);
  }
  return math.sqrt(variance / values.length);
}

double _luma(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b;
}
