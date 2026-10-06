import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/db/local_database.dart';
import '../../core/models/measurement.dart';
import '../../core/models/risk_level.dart';
import '../../core/risk/risk_engine.dart';
import '../../core/risk/risk_inputs.dart';
import '../../core/risk/risk_result.dart';
import 'mark_photo.dart';

class TestFlowView extends StatefulWidget {
  const TestFlowView({super.key, required this.onSaved, this.onOpenGuide});

  final Future<void> Function(Measurement measurement) onSaved;
  final ValueChanged<RiskResult>? onOpenGuide;

  @override
  State<TestFlowView> createState() => _TestFlowViewState();
}

class _TestFlowViewState extends State<TestFlowView> {
  final _engine = const RiskEngine();
  int _step = 0;
  SourceType _source = SourceType.unknown;
  bool? _turbid;
  bool? _smell;
  bool? _rain;
  bool? _latrine;
  bool? _cleanContainer;
  bool? _markVisible;
  String? _photoNote;
  RiskResult? _result;
  var _saving = false;
  var _exactLocation = false;
  String? _saveMessage;

  static const _questions = 6;

  void _next() {
    if (_step < _questions) {
      setState(() => _step += 1);
      return;
    }
    setState(() {
      _result = _engine.evaluate(RiskInputs(
        sourceType: _source,
        looksTurbid: _turbid,
        badSmell: _smell,
        recentRain: _rain,
        latrineOrAnimalsNearby: _latrine,
        cleanContainer: _cleanContainer,
        markVisible: _markVisible,
      ));
      _step = _questions + 1;
    });
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null || _saving) return;
    setState(() => _saving = true);
    double? lat;
    double? lng;
    double? accuracy;
    var precision = 'approx_100m';
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        accuracy = position.accuracy;
        if (_exactLocation) {
          lat = position.latitude;
          lng = position.longitude;
          precision = 'exact';
        } else {
          lat = approx100m(position.latitude);
          lng = approx100m(position.longitude);
        }
      }
    } catch (_) {}

    final measurement = Measurement(
      id: const Uuid().v4(),
      createdAt: DateTime.now().toUtc(),
      testType: 'visual',
      sourceType: _source,
      lat: lat,
      lng: lng,
      locationAccuracyM: accuracy,
      locationPrecision: precision,
      riskLevel: result.level,
      confidence: result.confidence,
      reasons: result.reasons,
      actions: result.actions,
      syncState: 'pending',
    );
    await widget.onSaved(measurement);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveMessage = 'Enregistré sur ce téléphone.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null && _step > _questions) return _resultPage();
    if (_step == _questions) return _photoPage();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _progress(),
        const SizedBox(height: 20),
        ..._questionWidgets(),
      ],
    );
  }

  Widget _progress() {
    return Row(
      children: [
        for (var i = 0; i < _questions; i++)
          Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i == _questions - 1 ? 0 : 6),
              color: i <= _step ? AppColors.teal : AppColors.line,
            ),
          ),
      ],
    );
  }

  List<Widget> _questionWidgets() => switch (_step) {
        0 => [
            _prompt('D’où vient l’eau ?'),
            Text(
                'Ceci guide le traitement. Ce n’est pas un certificat de potabilité.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ...SourceType.values.map(_sourceButton)
          ],
        1 => _yesNo('L’eau est-elle trouble ?', (value) => _turbid = value),
        2 => _yesNo('Une odeur anormale ?', (value) => _smell = value),
        3 =>
          _yesNo('A-t-il plu dans les 48 heures ?', (value) => _rain = value),
        4 => _yesNo('Une latrine ou des animaux sont-ils proches ?',
            (value) => _latrine = value),
        _ => _yesNo(
            'Le récipient est-il propre ?', (value) => _cleanContainer = value),
      };

  Widget _prompt(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _sourceButton(SourceType source) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () {
              _source = source;
              _next();
            },
            child: Row(
              children: [
                Expanded(child: Text(source.label)),
                const Icon(Icons.arrow_forward,
                    size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      );

  List<Widget> _yesNo(String title, void Function(bool?) assign) => [
        _prompt(title),
        Row(
          children: [
            Expanded(
                child: _choice('Oui', () {
              assign(true);
              _next();
            })),
            const SizedBox(width: 8),
            Expanded(
                child: _choice('Non', () {
              assign(false);
              _next();
            })),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              assign(null);
              _next();
            },
            child: const Text('Je ne sais pas'),
          ),
        ),
      ];

  Widget _choice(String label, VoidCallback onPressed) => OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );

  Widget _photoPage() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _prompt('Marque sous le gobelet (facultatif)'),
            const Text(
                'Posez le gobelet sur une marque noire imprimée. Si la photo est floue, elle est écartée.'),
            const SizedBox(height: 12),
            if (_photoNote != null) ...[
              const SizedBox(height: 16),
              Text(_photoNote!, style: Theme.of(context).textTheme.titleMedium),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _openCamera,
                  child: const Text('Prendre la photo')),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: _next, child: const Text('Continuer sans photo')),
            ),
          ],
        ),
      );

  Future<void> _openCamera() async {
    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (_) {
      cameras = [];
    }
    if (!mounted) return;
    if (cameras.isEmpty) {
      setState(
          () => _photoNote = 'Caméra indisponible. Le questionnaire suffit.');
      return;
    }
    final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => _CapturePage(camera: cameras.first)));
    if (!mounted || bytes == null) return;
    final read = await compute(readMark, bytes);
    setState(() {
      if (!read.sharpEnough) {
        _markVisible = null;
        _photoNote =
            'Photo écartée : trop floue. Reprenez-la ou continuez sans photo.';
      } else if (read.markVisible == null) {
        _markVisible = null;
        _photoNote = 'La photo ne tranche pas. Répondez aux questions.';
      } else {
        _markVisible = read.markVisible;
        _photoNote = read.markVisible!
            ? 'La marque semble encore visible.'
            : 'La marque semble avoir disparu : eau trouble.';
      }
    });
  }

  Widget _resultPage() {
    final result = _result!;
    final tone = AppColors.forRisk(result.level);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(result.level),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppColors.iconFor(result.level), color: tone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.level.label, style: text.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                          'Confiance ${(result.confidence * 100).round()} %. Indicatif, non certifié.',
                          style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('POURQUOI', style: text.labelSmall),
        const SizedBox(height: 8),
        ...result.reasons.map((reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(reason, style: text.bodyLarge),
            )),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Position précise'),
          subtitle:
              const Text('Sinon la position est arrondie à environ 100 m.'),
          value: _exactLocation,
          onChanged: (value) => setState(() => _exactLocation = value),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => widget.onOpenGuide?.call(result),
            child: const Text('Voir les actions'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? 'Enregistrement…'
                  : 'Enregistrer sur le téléphone')),
        ),
        if (_saveMessage != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_saveMessage!, style: text.bodyMedium)),
        TextButton(onPressed: _reset, child: const Text('Nouveau dépistage')),
      ],
    );
  }

  void _reset() => setState(() {
        _step = 0;
        _source = SourceType.unknown;
        _turbid = null;
        _smell = null;
        _rain = null;
        _latrine = null;
        _cleanContainer = null;
        _markVisible = null;
        _photoNote = null;
        _result = null;
        _saveMessage = null;
      });
}

class _CapturePage extends StatefulWidget {
  const _CapturePage({required this.camera});
  final CameraDescription camera;

  @override
  State<_CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<_CapturePage> {
  CameraController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final controller = CameraController(widget.camera, ResolutionPreset.medium,
        enableAudio: false);
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'La caméra n’a pas pu démarrer.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Cadrez la marque')),
      body: _error != null
          ? Center(child: Text(_error!))
          : controller == null || !controller.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(fit: StackFit.expand, children: [
                  CameraPreview(controller),
                  const Center(child: _Viewfinder(size: 180)),
                ]),
      floatingActionButton: controller == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final file = await controller.takePicture();
                final bytes = await file.readAsBytes();
                if (context.mounted) Navigator.pop(context, bytes);
              },
              child: const Icon(Icons.camera_alt),
            ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _CornerPainter(),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const arm = 28.0;
    final path = Path()
      ..moveTo(0, arm)
      ..lineTo(0, 0)
      ..lineTo(arm, 0)
      ..moveTo(size.width - arm, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, arm)
      ..moveTo(size.width, size.height - arm)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - arm, size.height)
      ..moveTo(arm, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
