import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../domain/entities/water_diagnostic.dart';

/// On-device classifier backed by the bundled TensorFlow Lite model.
class TfliteAiService {
  TfliteAiService({
    this.modelAssetPath = 'assets/models/model_unquant.tflite',
  });

  final String modelAssetPath;
  Interpreter? _interpreter;

  bool get isLoaded => _interpreter != null;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(modelAssetPath);
  }

  Future<WaterDiagnostic> analyzeImage(String path) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('The TFLite model has not been loaded.');
    }

    final decoded = img.decodeImage(await File(path).readAsBytes());
    if (decoded == null) {
      throw FormatException('Unable to decode image: $path');
    }

    final inputTensor = interpreter.getInputTensor(0);
    final inputShape = inputTensor.shape;
    if (inputShape.length != 4 || inputShape[0] != 1) {
      throw StateError('Unsupported TFLite input shape: $inputShape');
    }

    final resized = img.copyResize(
      decoded,
      width: inputShape[2],
      height: inputShape[1],
    );
    final input = _createInput(resized, inputTensor);
    final outputTensor = interpreter.getOutputTensor(0);
    final output = _createOutputBuffer(outputTensor);

    interpreter.run(input, output);

    final probabilities = _flattenOutput(output);
    if (probabilities.length < 3) {
      throw StateError('The TFLite model must return three class scores.');
    }

    final classIndex = _argmax(probabilities);
    final status = WaterDiagnosticStatus.values[classIndex.clamp(0, 2)];
    final warningProbability = probabilities[1].clamp(0.0, 1.0);
    final dangerProbability = probabilities[2].clamp(0.0, 1.0);
    final turbidityScore =
        (warningProbability * 0.55 + dangerProbability).clamp(0.0, 1.0);

    return WaterDiagnostic.fromModelScores(
      status: status,
      turbidityScore: turbidityScore,
      confidence: probabilities[classIndex].clamp(0.0, 1.0),
    );
  }

  Object _createInput(img.Image image, Tensor tensor) {
    final pixels = [
      for (var y = 0; y < image.height; y++)
        for (var x = 0; x < image.width; x++) image.getPixel(x, y),
    ];
    final values = [
      for (final pixel in pixels) ...[
        pixel.r,
        pixel.g,
        pixel.b,
      ],
    ];

    if (tensor.type == TensorType.float32) {
      return [
        for (final value in values) value.toDouble() / 255.0,
      ].reshape(tensor.shape);
    }
    return values.map((value) => value.round()).toList().reshape(tensor.shape);
  }

  Object _createOutputBuffer(Tensor tensor) {
    final size = tensor.shape.fold<int>(1, math.max);
    if (tensor.type == TensorType.float32) {
      return List<double>.filled(size, 0).reshape(tensor.shape);
    }
    return List<int>.filled(size, 0).reshape(tensor.shape);
  }

  List<double> _flattenOutput(Object output) {
    if (output is List) {
      return output.expand((value) => _flattenOutput(value)).toList();
    }
    return [(output as num).toDouble()];
  }

  int _argmax(List<double> values) {
    var bestIndex = 0;
    for (var index = 1; index < values.length; index++) {
      if (values[index] > values[bestIndex]) bestIndex = index;
    }
    return bestIndex;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
