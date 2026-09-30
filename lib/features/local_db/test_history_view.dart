import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/water_test_model.dart';
import '../../core/repositories/local_database.dart';

class TestHistoryView extends StatefulWidget {
  const TestHistoryView({super.key});

  @override
  State<TestHistoryView> createState() => _TestHistoryViewState();
}

class _TestHistoryViewState extends State<TestHistoryView> {
  late Future<List<WaterTestModel>> _tests;

  @override
  void initState() {
    super.initState();
    _tests = LocalDatabase.instance.getTests();
  }

  Future<void> _export() async {
    final tests = await _tests;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export JSON'),
        content: SelectableText(jsonEncode(tests.map((test) => test.toMap()).toList())),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      floatingActionButton: FloatingActionButton.extended(onPressed: _export, icon: const Icon(Icons.ios_share), label: const Text('Export JSON')),
        body: FutureBuilder<List<WaterTestModel>>(
          future: _tests,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.isEmpty) return const Center(child: Text('Aucun test enregistré'));
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final test = snapshot.data![index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: _color(test.status), radius: 8),
                  title: Text(test.status.name.toUpperCase()),
                  subtitle: Text(test.timestamp.toLocal().toString()),
                  trailing: Text(test.turbidityScore.toStringAsFixed(1)),
                );
              },
            );
          },
        ),
      );

  Color _color(WaterTestStatus status) => switch (status) {
        WaterTestStatus.safe => AppColors.safe,
        WaterTestStatus.warning => AppColors.warning,
        WaterTestStatus.danger => AppColors.danger,
      };
}
