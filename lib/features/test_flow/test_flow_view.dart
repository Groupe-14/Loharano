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
  const TestFlowView({super.key, required this.onSaved, this.onSpeak});

  final Future<void> Function(Measurement measurement) onSaved;
  final Future<void> Function(String text)? onSpeak;

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
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
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
      _saveMessage =
          'Enregistré sur ce téléphone. Rien n’est envoyé tant que Supabase n’est pas configuré.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null && _step > _questions) return _resultPage();
    if (_step == _questions) return _photoPage();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Dépistage ${_step + 1}/$_questions',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
            'Ceci guide le traitement. Ce n’est pas un certificat de potabilité.'),
        const SizedBox(height: 20),
        ..._question,
      ],
    );
  }

  List<Widget> get _question => switch (_step) {
        0 => [
            _prompt('D’où vient l’eau ?'),
            ...SourceType.values.map(_sourceButton)
          ],
        1 => _yesNo(
            'L’eau est-elle trouble ?', _turbid, (value) => _turbid = value),
        2 => _yesNo('Une odeur anormale ?', _smell, (value) => _smell = value),
        3 => _yesNo(
            'A-t-il plu dans les 48 heures ?', _rain, (value) => _rain = value),
        4 => _yesNo('Une latrine ou des animaux sont-ils proches ?', _latrine,
            (value) => _latrine = value),
        _ => _yesNo('Le récipient est-il propre ?', _cleanContainer,
            (value) => _cleanContainer = value),
      };

  Widget _prompt(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)));

  Widget _sourceButton(SourceType source) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              _source = source;
              _next();
            },
            child: Text(source.label, style: const TextStyle(fontSize: 18)),
          ),
        ),
      );

  List<Widget> _yesNo(
          String title, bool? current, void Function(bool?) assign) =>
      [
        _prompt(title),
        _choice('Oui', current == true, () {
          assign(true);
          _next();
        }),
        _choice('Non', current == false, () {
          assign(false);
          _next();
        }),
        _choice('Je ne sais pas', current == null && _step > 0, () {
          assign(null);
          _next();
        }),
      ];

  Widget _choice(String label, bool _, VoidCallback onPressed) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.tonal(
              onPressed: onPressed,
              child: Text(label, style: const TextStyle(fontSize: 18))),
        ),
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
            if (_photoNote != null)
              Text(_photoNote!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                    onPressed: _openCamera,
                    child: const Text('Prendre la photo'))),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                    onPressed: _next,
                    child: const Text('Continuer sans photo'))),
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
        _photoNote =
            'Marque incertaine. Répondez vous-même : elle est ${read.contrast.toStringAsFixed(0)} de contraste.';
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
    final color = switch (result.level) {
      RiskLevel.low => AppColors.low,
      RiskLevel.medium => AppColors.medium,
      RiskLevel.high => AppColors.high,
      RiskLevel.unknown => AppColors.unknown,
    };
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(children: [
          Icon(Icons.circle, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(result.level.label,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 8),
        Text(
            'Confiance du dépistage visuel : ${(result.confidence * 100).round()} %. Indicatif, non certifié.'),
        const SizedBox(height: 16),
        const Text('Pourquoi', style: TextStyle(fontWeight: FontWeight.bold)),
        ...result.reasons.map((reason) => Padding(
            padding: const EdgeInsets.only(top: 6), child: Text('• $reason'))),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Position précise'),
          subtitle:
              const Text('Sinon la position est arrondie à environ 100 m.'),
          value: _exactLocation,
          onChanged: (value) => setState(() => _exactLocation = value),
        ),
        const SizedBox(height: 8),
        FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(
                _saving ? 'Enregistrement…' : 'Enregistrer sur le téléphone')),
        if (_saveMessage != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_saveMessage!)),
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
                  Center(
                      child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                              border:
                                  Border.all(color: Colors.white, width: 3)))),
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
