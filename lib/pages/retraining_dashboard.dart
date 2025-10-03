import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../config.dart';
import '../widgets/training_visualizations.dart';

class RetrainingDashboardPage extends StatefulWidget {
  const RetrainingDashboardPage({Key? key}) : super(key: key);

  @override
  State<RetrainingDashboardPage> createState() =>
      _RetrainingDashboardPageState();
}

class _RetrainingDashboardPageState extends State<RetrainingDashboardPage> {
  List<Map<String, dynamic>> _modelVersions = [];
  Map<String, dynamic>? _selectedModel;
  bool _loading = false;
  bool _retraining = false;
  String? _uploadStatus;
  File? _selectedFile;
  String _mergeMode = 'merge';

  @override
  void initState() {
    super.initState();
    _loadModelVersions();
  }

  Future<void> _loadModelVersions() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/models/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _modelVersions =
              List<Map<String, dynamic>>.from(data['versions'] ?? []);
        });
      }
    } catch (e) {
      _showError('Failed to load model versions: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadModelDetails(int versionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/models/$versionId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedModel = data['version'];
        });
      }
    } catch (e) {
      _showError('Failed to load model details: $e');
    }
  }

  Future<void> _retrainModel() async {
    setState(() => _retraining = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError('Login required');
        return;
      }

      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/retrain/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSuccess('Model retrained successfully!');
          await _loadModelVersions();
          // Load details of the new model
          if (_modelVersions.isNotEmpty) {
            await _loadModelDetails(_modelVersions.first['id']);
          }
        } else {
          _showError(data['error'] ?? 'Retraining failed');
        }
      } else {
        _showError('Retraining failed (${response.statusCode})');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _retraining = false);
    }
  }

  Future<void> _uploadCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
        _showUploadDialog();
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _showUploadDialog() async {
    if (_selectedFile == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload CSV Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('File: ${_selectedFile!.path.split('/').last}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _mergeMode,
              decoration: const InputDecoration(labelText: 'Upload Mode'),
              items: const [
                DropdownMenuItem(
                    value: 'merge', child: Text('Merge with existing data')),
                DropdownMenuItem(
                    value: 'replace', child: Text('Replace existing data')),
              ],
              onChanged: (value) {
                setState(() => _mergeMode = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performUpload();
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _performUpload() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError('Login required');
        return;
      }

      final baseUrl = await AppConfig.getBaseUrl();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload-csv/'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files
          .add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
      request.fields['merge_mode'] = _mergeMode;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success']) {
          _showSuccess(
              'CSV uploaded successfully! ${data['records_added']} records added.');
          setState(() {
            _selectedFile = null;
            _uploadStatus = 'Upload completed';
          });
        } else {
          _showError(data['error'] ?? 'Upload failed');
        }
      } else {
        _showError('Upload failed (${response.statusCode})');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deployModel(int versionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError('Login required');
        return;
      }

      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/models/$versionId/deploy/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSuccess('Model deployed successfully!');
          await _loadModelVersions();
        } else {
          _showError(data['error'] ?? 'Deployment failed');
        }
      } else {
        _showError('Deployment failed (${response.statusCode})');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Retraining Dashboard'),
        actions: [
          IconButton(
            onPressed: _loadModelVersions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUploadSection(),
                  const SizedBox(height: 24),
                  _buildRetrainSection(),
                  const SizedBox(height: 24),
                  _buildModelVersionsSection(),
                  if (_selectedModel != null) ...[
                    const SizedBox(height: 24),
                    _buildModelDetailsSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload / Add Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _uploadCsv,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                ),
                const SizedBox(width: 16),
                if (_selectedFile != null)
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedFile!.path.split('/').last}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
              ],
            ),
            if (_uploadStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _uploadStatus!,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetrainSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Retrain Model',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retraining ? null : _retrainModel,
              icon: _retraining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_fill),
              label: Text(_retraining ? 'Retraining...' : 'Retrain Model'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trains Random Forest model with current dataset. Shows performance metrics after training.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelVersionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Model Versions & Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_modelVersions.isEmpty)
              const Text('No model versions found')
            else
              ..._modelVersions.map((version) => _buildVersionCard(version)),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(Map<String, dynamic> version) {
    return ModelVersionCard(
      version: version,
      onDeploy: version['is_active'] == true
          ? null
          : () => _deployModel(version['id']),
      onViewDetails: () => _loadModelDetails(version['id']),
    );
  }

  Widget _buildModelDetailsSection() {
    if (_selectedModel == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training Results - ${_selectedModel!['version']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 16),
            FeatureImportanceChart(
              featureImportance: _selectedModel!['feature_importance'],
            ),
            const SizedBox(height: 16),
            TrainingMetricsChart(
              trainingMetrics: _selectedModel!['training_metrics'],
            ),
            const SizedBox(height: 16),
            ConfusionMatrixWidget(
              matrix: _selectedModel!['confusion_matrix']['matrix'],
              labels: _selectedModel!['confusion_matrix']['labels'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      children: [
        _buildMetricCard('Accuracy',
            '${(_selectedModel!['accuracy'] * 100).toStringAsFixed(1)}%'),
        _buildMetricCard('Precision',
            '${(_selectedModel!['precision'] * 100).toStringAsFixed(1)}%'),
        _buildMetricCard('Recall',
            '${(_selectedModel!['recall'] * 100).toStringAsFixed(1)}%'),
        _buildMetricCard('F1-Score',
            '${(_selectedModel!['f1_score'] * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
