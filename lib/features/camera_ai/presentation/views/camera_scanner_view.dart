import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/water_diagnostic.dart';
import '../controllers/camera_ai_controller.dart';
import '../widgets/pitch_demo_panel.dart';
import '../widgets/result_dashboard_widget.dart';
import '../../../local_db/data/services/sync_engine_service.dart';
import '../../../purification/purification_guide_view.dart';

// ─── Vue principale ──────────────────────────────────────────────────────────

class CameraScannerView extends StatefulWidget {
  const CameraScannerView({super.key, this.controller, this.onDiagnostic});

  final CameraAiController? controller;
  final ValueChanged<WaterDiagnostic>? onDiagnostic;

  @override
  State<CameraScannerView> createState() => _CameraScannerViewState();
}

class _CameraScannerViewState extends State<CameraScannerView>
    with WidgetsBindingObserver {
  // ── Controller ──────────────────────────────────────────────────────────
  late final CameraAiController _aiController;
  late final bool _ownsController;

  // ── Caméra ──────────────────────────────────────────────────────────────
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _cameraPermissionGranted = false;
  bool _cameraInitialized = false;
  bool _torchOn = false;
  String? _cameraError;

  // ── UI state ─────────────────────────────────────────────────────────────
  DateTime? _savedDiagnosticTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _aiController = widget.controller ?? CameraAiController();
    _aiController.addListener(_onControllerChanged);
    _initCamera();
  }

  // ─── Cycle de vie ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _cameraController;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
      _cameraController = null;
      _cameraInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _aiController.removeListener(_onControllerChanged);
    if (_ownsController) _aiController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ─── Initialisation caméra ───────────────────────────────────────────────

  Future<void> _initCamera() async {
    // 1. Demande de permission
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (!status.isGranted) {
      setState(() {
        _cameraPermissionGranted = false;
        _cameraError = status.isPermanentlyDenied
            ? 'Permission caméra refusée définitivement. '
                'Activez-la dans les paramètres de l\'application.'
            : 'Permission caméra refusée. Appuyez pour réessayer.';
      });
      return;
    }

    setState(() {
      _cameraPermissionGranted = true;
      _cameraError = null;
    });

    // 2. Enumération des caméras disponibles
    try {
      _cameras = await availableCameras();
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Caméra indisponible sur cet appareil.');
      }
      return;
    }

    if (_cameras.isEmpty) {
      if (mounted) {
        setState(() => _cameraError = 'Aucune caméra détectée.');
      }
      return;
    }

    // 3. Initialisation avec la caméra arrière principale
    final backCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );
    await _startCamera(backCamera);
  }

  Future<void> _startCamera(CameraDescription description) async {
    final prev = _cameraController;
    if (prev != null) {
      await prev.dispose();
    }

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      _cameraInitialized = true;
      _cameraError = null;
      setState(() {});
    } catch (e) {
      await controller.dispose();
      if (mounted) {
        setState(() {
          _cameraInitialized = false;
          _cameraError =
              'Impossible d\'initialiser la caméra : ${e.toString()}';
        });
      }
    }
  }

  // ─── Actions capture ──────────────────────────────────────────────────────

  Future<void> _capturePhoto() async {
    final cam = _cameraController;
    if (cam == null || !cam.value.isInitialized || _aiController.isAnalyzing) {
      return;
    }

    try {
      final xFile = await cam.takePicture();
      if (!mounted) return;
      await _aiController.processCapturedImage(xFile.path);
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur lors de la capture : ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _importFromGallery() async {
    if (_aiController.isAnalyzing) return;
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xFile == null || !mounted) return;

      // Copier dans le répertoire de l'app pour garantir un accès durable
      final appDir = await getApplicationDocumentsDirectory();
      final destPath =
          p.join(appDir.path, 'water_samples', p.basename(xFile.path));
      await Directory(p.dirname(destPath)).create(recursive: true);
      await File(xFile.path).copy(destPath);

      await _aiController.processCapturedImage(destPath);
    } catch (e) {
      if (mounted) {
        _showSnack('Impossible d\'importer l\'image.', isError: true);
      }
    }
  }

  Future<void> _toggleTorch() async {
    final cam = _cameraController;
    if (cam == null || !cam.value.isInitialized) return;
    try {
      _torchOn = !_torchOn;
      await cam.setFlashMode(
          _torchOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (_) {
      // Torche non supportée → ignorer silencieusement
    }
  }

  // ─── Listener controller IA ──────────────────────────────────────────────

  void _onControllerChanged() {
    final diagnostic = _aiController.diagnostic;
    if (diagnostic != null &&
        _savedDiagnosticTimestamp != diagnostic.timestamp) {
      _savedDiagnosticTimestamp = diagnostic.timestamp;
      widget.onDiagnostic?.call(diagnostic);
      unawaited(_navigateToPurification(diagnostic));
    }
    if (mounted) setState(() {});
  }

  Future<void> _navigateToPurification(WaterDiagnostic diagnostic) async {
    // La persistance est déjà effectuée dans le use-case / controller.
    // Ici on tente juste la synchro réseau si disponible.
    try {
      unawaited(SyncEngineService.instance.syncPendingTests());
    } catch (_) {}

    if (!mounted) return;

    // Construire le WaterTestModel depuis le diagnostic pour la vue purification
    final waterTest = diagnostic.toWaterTestModel(imagePath: null);

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) =>
            PurificationGuideView(waterTest: waterTest),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Viewfinder ──────────────────────────────────────────────────
          _buildViewfinder(),

          // ── Barre d'actions ─────────────────────────────────────────────
          _buildActionBar(),

          // ── État du modèle ───────────────────────────────────────────────
          if (_aiController.isModelLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Chargement du modèle IA…',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),

          // ── Message TFLite fallback ──────────────────────────────────────
          if (!_aiController.isTfliteActive && !_aiController.isModelLoading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: Colors.black45),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Analyse chromatique RVB/HSV active (mode offline)',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),

          // ── Analyse en cours ─────────────────────────────────────────────
          if (_aiController.isAnalyzing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: _AnalyzingIndicator(),
            ),

          // ── Erreur ───────────────────────────────────────────────────────
          if (_aiController.errorMessage != null)
            _ErrorBanner(message: _aiController.errorMessage!),

          // ── Résultats ────────────────────────────────────────────────────
          if (_aiController.diagnostic case final diag?) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ResultDashboardWidget(diagnostic: diag),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return GestureDetector(
      onLongPress: () => PitchDemoPanel.show(
        context,
        onStatusSelected: _aiController.forceStatus,
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fond / prévisualisation caméra ────────────────────────────
            ClipRect(child: _buildCameraPreview()),

            // ── Overlay : grille de cadrage ───────────────────────────────
            CustomPaint(painter: _ViewfinderPainter()),

            // ── Overlay : message état ────────────────────────────────────
            if (_cameraError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt_outlined,
                          color: Colors.white54, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _cameraError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      if (!_cameraPermissionGranted) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _initCamera,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // ── Bouton torche ──────────────────────────────────────────────
            if (_cameraInitialized)
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off_outlined),
                  tooltip: 'Lampe torche',
                  onPressed: _toggleTorch,
                ),
              ),

            // ── Instruction ────────────────────────────────────────────────
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Centrez la bandelette dans le cadre',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(Icons.water_drop, color: Colors.white12, size: 80),
        ),
      );
    }
    return CameraPreview(_cameraController!);
  }

  Widget _buildActionBar() {
    final isAnalyzing = _aiController.isAnalyzing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Galerie
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isAnalyzing ? null : _importFromGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('Galerie'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryBlue.withAlpha(150)),
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Bouton capture principal
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: isAnalyzing
                  ? null
                  : (_cameraInitialized
                      ? _capturePhoto
                      : _importFromGallery),
              icon: const Icon(Icons.camera_alt),
              label: Text(
                isAnalyzing
                    ? 'Analyse…'
                    : _cameraInitialized
                        ? 'Capturer'
                        : 'Importer',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Reset
          if (_aiController.diagnostic != null)
            IconButton.outlined(
              onPressed: _aiController.reset,
              icon: const Icon(Icons.refresh),
              tooltip: 'Nouveau test',
              color: AppColors.primaryBlue,
            ),
        ],
      ),
    );
  }

  // ─── Helpers UI ───────────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.danger : AppColors.safe,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─── Sous-widgets ────────────────────────────────────────────────────────────

class _AnalyzingIndicator extends StatelessWidget {
  const _AnalyzingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Analyse en cours…',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Extraction des paramètres physico-chimiques',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withAlpha(80)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: AppColors.danger, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CustomPainter : grille de cadrage ───────────────────────────────────────

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.primaryBlue.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Cadre central (60% × 80% de la vue)
    final rx = size.width * 0.20;
    final ry = size.height * 0.10;
    final rw = size.width * 0.60;
    final rh = size.height * 0.80;
    final rect = Rect.fromLTWH(rx, ry, rw, rh);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.drawRRect(rrect, borderPaint);

    // Coins d'accroche (L-shapes)
    const cs = 20.0; // longueur du coin
    final corners = [
      [Offset(rx, ry + cs), Offset(rx, ry), Offset(rx + cs, ry)],
      [
        Offset(rx + rw - cs, ry),
        Offset(rx + rw, ry),
        Offset(rx + rw, ry + cs)
      ],
      [
        Offset(rx + rw, ry + rh - cs),
        Offset(rx + rw, ry + rh),
        Offset(rx + rw - cs, ry + rh)
      ],
      [
        Offset(rx + cs, ry + rh),
        Offset(rx, ry + rh),
        Offset(rx, ry + rh - cs)
      ],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, cornerPaint);
    }

    // Réticule central (croix)
    final centerX = rx + rw / 2;
    final centerY = ry + rh / 2;
    final crossPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(centerX - 10, centerY), Offset(centerX + 10, centerY), crossPaint);
    canvas.drawLine(
        Offset(centerX, centerY - 10), Offset(centerX, centerY + 10), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
