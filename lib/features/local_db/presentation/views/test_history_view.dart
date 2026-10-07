import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/water_test_model.dart';
import '../../../audio_qr/data/services/speech_service.dart';
import '../../../audio_qr/presentation/widgets/diagnostic_qr_dialog.dart';
import '../../data/services/data_export_service.dart';
import '../../data/services/local_db_service.dart';
import '../../data/services/sync_engine_service.dart';

class TestHistoryView extends StatefulWidget {
  const TestHistoryView({super.key});

  @override
  State<TestHistoryView> createState() => _TestHistoryViewState();
}

class _TestHistoryViewState extends State<TestHistoryView> {
  final _exportService = const DataExportService();
  final _speech = SpeechService();
  List<WaterTestModel> _tests = const [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    final tests = await LocalDbService.instance.getAllTests();
    if (!mounted) return;
    setState(() {
      _tests = tests;
      _loading = false;
    });
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final count = await SyncEngineService.instance.syncPendingTests();
      await _loadTests();
      if (mounted) _showMessage('$count test(s) synchronisé(s).');
    } catch (_) {
      if (mounted) _showMessage('La synchronisation a échoué.');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _showExport() async {
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Exporter en CSV'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('Exporter en JSON'),
              onTap: () => Navigator.pop(context, 'json'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || format == null) return;
    final content = format == 'csv'
        ? _exportService.toCsv(_tests)
        : _exportService.toJson(_tests);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export ${format.toUpperCase()}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(content)),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) {
                _showMessage('Export copié dans le presse-papiers.');
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: 'Synchroniser',
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_sync),
            ),
            IconButton(
              tooltip: 'Exporter',
              onPressed: _showExport,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _tests.isEmpty
                ? const Center(child: Text('Aucun test enregistré'))
                : RefreshIndicator(
                    onRefresh: _loadTests,
                    child: ListView.builder(
                      itemCount: _tests.length,
                      itemBuilder: (context, index) => _TestTile(
                        test: _tests[index],
                        onSpeak: () => _speech.speak(
                          _instructionsFor(_tests[index]),
                        ),
                        onShare: () => showDiagnosticQrDialog(
                          context,
                          _tests[index],
                        ),
                      ),
                    ),
                  ),
      );

  String _instructionsFor(WaterTestModel test) => switch (test.status) {
        WaterTestStatus.safe =>
          'Eau sûre. Couvrez le récipient et gardez-le au frais.',
        WaterTestStatus.warning =>
          'Décantez puis filtrez l’eau sur un tissu propre. Faites bouillir avant de boire.',
        WaterTestStatus.danger =>
          'Danger. Ne buvez pas cette eau. Décantez, filtrez, faites bouillir et chlorez selon les consignes locales.',
      };
}

class _TestTile extends StatelessWidget {
  const _TestTile({
    required this.test,
    required this.onSpeak,
    required this.onShare,
  });

  final WaterTestModel test;
  final VoidCallback onSpeak;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: _color(test.status),
          child: Icon(_icon(test.status), color: Colors.white),
        ),
        title: Text(test.status.name.toUpperCase()),
        subtitle: Text(
          '${_formatDate(test.timestamp)}\n'
          'GPS: ${test.latitude?.toStringAsFixed(5) ?? '—'}, '
          '${test.longitude?.toStringAsFixed(5) ?? '—'}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${test.turbidityScore.toStringAsFixed(1)} NTU'),
                Icon(
                  test.isSynced ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                  color: test.isSynced ? AppColors.safe : Colors.grey,
                ),
              ],
            ),
            IconButton(
              tooltip: 'Lire',
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_outlined),
            ),
            IconButton(
              tooltip: 'Partager par QR',
              onPressed: onShare,
              icon: const Icon(Icons.qr_code_2),
            ),
          ],
        ),
      );

  String _formatDate(DateTime date) =>
      date.toLocal().toString().split('.').first;

  IconData _icon(WaterTestStatus status) => switch (status) {
        WaterTestStatus.safe => Icons.check,
        WaterTestStatus.warning => Icons.warning_amber,
        WaterTestStatus.danger => Icons.dangerous,
      };

  Color _color(WaterTestStatus status) => switch (status) {
        WaterTestStatus.safe => AppColors.safe,
        WaterTestStatus.warning => AppColors.warning,
        WaterTestStatus.danger => AppColors.danger,
      };
}
