import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/crop_collection.dart';
import '../services/crop_collection_storage.dart';
import '../config.dart';
import '../services/sensor_bus.dart';

class CropDataDashboardPage extends StatefulWidget {
  const CropDataDashboardPage({Key? key}) : super(key: key);

  @override
  State<CropDataDashboardPage> createState() => _CropDataDashboardPageState();
}

class _CropDataDashboardPageState extends State<CropDataDashboardPage> {
  final CropCollectionStorage _storage = CropCollectionStorage();
  final List<CropCollectionSession> _sessions = [];
  bool _loading = true;
  final Set<String> _autoCollectSessionIds = <String>{};
  StreamSubscription<SensorReading>? _sensorSub;

  @override
  void initState() {
    super.initState();
    _load();
    _sensorSub = SensorBus.instance.stream.listen(_onSensorReading);
  }

  Future<void> _load() async {
    final sessions = await _storage.loadSessions();
    setState(() {
      _sessions
        ..clear()
        ..addAll(sessions);
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _storage.saveSessions(_sessions);
    setState(() {});
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }

  void _onSensorReading(SensorReading reading) {
    if (_autoCollectSessionIds.isEmpty) return;
    bool changed = false;
    for (final s in _sessions) {
      if (_autoCollectSessionIds.contains(s.id)) {
        s.records.add(CropRecord(
          nitrogen: reading.nitrogen,
          phosphorus: reading.phosphorus,
          potassium: reading.potassium,
          temperature: reading.temperature,
          humidity: reading.humidity,
          ph: reading.ph,
          rainfall: reading.rainfall,
          createdAt: reading.timestamp,
        ));
        changed = true;
      }
    }
    if (changed) {
      _save();
    }
  }

  Future<void> _addSessionDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();
    final uuid = const Uuid();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Crop'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Crop name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter crop name' : null,
              ),
              TextFormField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              TextFormField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Target records (default 100)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final parsed = int.tryParse(targetCtrl.text.trim());
      final target = parsed == null
          ? 100
          : parsed < 1
              ? 1
              : (parsed > 100000 ? 100000 : parsed);
      _sessions.add(CropCollectionSession(
        id: uuid.v4(),
        cropName: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        metadata: {},
        targetCount: target,
      ));
      await _save();
    }
  }

  Future<void> _addRecordDialog(CropCollectionSession session) async {
    final n = TextEditingController();
    final p = TextEditingController();
    final k = TextEditingController();
    final t = TextEditingController();
    final h = TextEditingController();
    final ph = TextEditingController();
    final r = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Record - ${session.cropName}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _numField(n, 'Nitrogen (N)'),
                _numField(p, 'Phosphorus (P)'),
                _numField(k, 'Potassium (K)'),
                _numField(t, 'Temperature (°C)'),
                _numField(h, 'Humidity (%)'),
                _numField(ph, 'pH'),
                _numField(r, 'Rainfall (mm)'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate())
                Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true) {
      session.records.add(CropRecord(
        nitrogen: double.parse(n.text),
        phosphorus: double.parse(p.text),
        potassium: double.parse(k.text),
        temperature: double.parse(t.text),
        humidity: double.parse(h.text),
        ph: double.parse(ph.text),
        rainfall: double.parse(r.text),
      ));
      await _save();
    }
  }

  Future<void> _exportCsvDialog() async {
    // Build CSV from all sessions
    final header = 'N,P,K,temperature,humidity,ph,rainfall,label';
    final lines = <String>[header];
    for (final s in _sessions) {
      lines.addAll(s.toCsvLines());
    }
    final csvContent = lines.join('\n');

    // Simple share/save approach: show dialog with copy option
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CSV Preview'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(child: Text(csvContent)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _triggerRetrain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login required to retrain model.')),
        );
        return;
      }
      // Best-effort: use the same base URL logic as elsewhere
      final baseUrl = await AppConfig.getBaseUrl();
      final resp = await http.post(
        Uri.parse('$baseUrl/api/retrain/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retraining triggered.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retrain failed (${resp.statusCode}).')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Data Dashboard'),
        actions: [
          IconButton(
              onPressed: _exportCsvDialog,
              icon: const Icon(Icons.file_download)),
          IconButton(
              onPressed: _triggerRetrain,
              icon: const Icon(Icons.play_circle_fill)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSessionDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('No crops yet. Tap + to add one.'))
              : ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) => _sessionTile(_sessions[i]),
                ),
    );
  }

  Widget _sessionTile(CropCollectionSession s) {
    final pct = (s.progressRatio * 100).clamp(0, 100).toStringAsFixed(0);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.cropName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    _sessions.removeWhere((x) => x.id == s.id);
                    await _save();
                  },
                  icon: const Icon(Icons.delete_outline),
                )
              ],
            ),
            if (s.description != null && s.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(s.description!),
              ),
            LinearProgressIndicator(value: s.progressRatio),
            const SizedBox(height: 6),
            Text(
                '${s.progressCount}/${s.targetCount} records collected ($pct%)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addRecordDialog(s),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Record'),
                ),
                FilterChip(
                  selected: _autoCollectSessionIds.contains(s.id),
                  label: const Text('Auto-collect'),
                  onSelected: (sel) async {
                    setState(() {
                      if (sel) {
                        _autoCollectSessionIds.add(s.id);
                      } else {
                        _autoCollectSessionIds.remove(s.id);
                      }
                    });
                  },
                ),
                OutlinedButton.icon(
                  onPressed: s.records.isEmpty
                      ? null
                      : () async {
                          // Duplicate last record as a quick helper
                          final last = s.records.last;
                          s.records.add(CropRecord(
                            nitrogen: last.nitrogen,
                            phosphorus: last.phosphorus,
                            potassium: last.potassium,
                            temperature: last.temperature,
                            humidity: last.humidity,
                            ph: last.ph,
                            rainfall: last.rainfall,
                          ));
                          await _save();
                        },
                  icon: const Icon(Icons.content_copy),
                  label: const Text('Duplicate Last'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final x = double.tryParse(v);
        if (x == null || x.isNaN || !x.isFinite) return 'Enter a valid number';
        return null;
      },
    );
  }
}
