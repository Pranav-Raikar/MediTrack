// ─────────────────────────────────────────────────────────────────────────────
// screens/vitals/add_vital_screen.dart  —  Log a New Health Reading
//
// Dynamically changes fields based on type selected:
//   blood_pressure → systolic + diastolic fields
//   others         → single value field
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/vital.dart';
import '../../services/firestore_service.dart';

class AddVitalScreen extends StatefulWidget {
  final String defaultType;
  const AddVitalScreen({super.key, required this.defaultType});

  @override
  State<AddVitalScreen> createState() => _AddVitalScreenState();
}

class _AddVitalScreenState extends State<AddVitalScreen> {
  final _valueController  = TextEditingController(); // systolic / main value
  final _value2Controller = TextEditingController(); // diastolic (BP only)
  final _notesController  = TextEditingController();
  final _formKey          = GlobalKey<FormState>();
  bool _isLoading         = false;
  late String _selectedType;

  // Maps each type to its display name + unit
  static const _typeConfig = {
    'blood_pressure': {'label': 'Blood Pressure', 'unit': 'mmHg', 'hint': '120'},
    'blood_sugar':    {'label': 'Blood Sugar',    'unit': 'mg/dL','hint': '95'},
    'weight':         {'label': 'Weight',          'unit': 'kg',   'hint': '70'},
    'heart_rate':     {'label': 'Heart Rate',      'unit': 'bpm',  'hint': '72'},
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
  }

  String get _unit => _typeConfig[_selectedType]!['unit']!;
  bool get _isBP  => _selectedType == 'blood_pressure';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final vital = Vital(
      id:         const Uuid().v4(),
      type:       _selectedType,
      value:      double.parse(_valueController.text.trim()),
      value2:     _isBP ? _value2Controller.text.trim() : null,
      unit:       _unit,
      recordedAt: DateTime.now(),
      notes:      _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
    );

    try {
      await FirestoreService.addVital(vital);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reading saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _value2Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Reading'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Type Selector (segmented button) ──────────────────────
              Text('Vital Type',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Show type as large tappable chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _typeConfig.entries.map((entry) {
                  final selected = _selectedType == entry.key;
                  return FilterChip(
                    label: Text(entry.value['label']!),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedType = entry.key),
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Value Input ──────────────────────────────────────────
              if (_isBP) ...[
                // Blood Pressure: two fields (systolic / diastolic)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Systolic',
                          hintText: '120',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('/',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _value2Controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Diastolic',
                          hintText: '80',
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // All other vitals: single value
                TextFormField(
                  controller: _valueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _typeConfig[_selectedType]!['label'],
                    hintText: _typeConfig[_selectedType]!['hint'],
                    suffixText: _unit,
                    prefixIcon: const Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter a value' : null,
                ),
              ],
              const SizedBox(height: 16),

              // ── Normal Range Info Box ─────────────────────────────────
              _NormalRangeCard(type: _selectedType),
              const SizedBox(height: 16),

              // ── Notes ────────────────────────────────────────────────
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. After exercise, fasting reading',
                  prefixIcon: const Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Save ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label:
                      const Text('Save Reading', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NormalRangeCard  —  Shows what a healthy range looks like for each vital
// ─────────────────────────────────────────────────────────────────────────────
class _NormalRangeCard extends StatelessWidget {
  final String type;
  const _NormalRangeCard({required this.type});

  static const _ranges = {
    'blood_pressure': '🟢  Normal: 90/60 – 120/80 mmHg',
    'blood_sugar':    '🟢  Fasting normal: 70 – 100 mg/dL',
    'weight':         '🟢  Healthy BMI range: 18.5 – 24.9',
    'heart_rate':     '🟢  Resting normal: 60 – 100 bpm',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Text(
        _ranges[type] ?? '',
        style: const TextStyle(fontSize: 13, color: Colors.green),
      ),
    );
  }
}
