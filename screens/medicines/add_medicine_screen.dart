// ─────────────────────────────────────────────────────────────────────────────
// screens/medicines/add_medicine_screen.dart  —  Add New Medicine Form
//
// FEATURES:
//  - Name + dosage input
//  - Frequency dropdown (auto-sets reminder times)
//  - Tap each time chip to open time picker
//  - On save: stores in Firestore + schedules local notifications
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/medicine.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _nameController   = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController  = TextEditingController();
  final _formKey          = GlobalKey<FormState>();

  String _frequency = 'Once daily';
  List<String> _times = ['08:00'];
  bool _isLoading = false;

  // All available frequency options
  static const _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every 4 hours',
    'As needed',
  ];

  /// Open the time picker for a specific reminder slot
  Future<void> _pickTime(int index) async {
    final parts = _times[index].split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour:   int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (picked != null) {
      setState(() {
        _times[index] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  /// When frequency changes, auto-populate sensible default times
  void _onFrequencyChanged(String freq) {
    setState(() {
      _frequency = freq;
      switch (freq) {
        case 'Once daily':
          _times = ['08:00'];
          break;
        case 'Twice daily':
          _times = ['08:00', '20:00'];
          break;
        case 'Three times daily':
          _times = ['08:00', '14:00', '20:00'];
          break;
        case 'Every 4 hours':
          _times = ['06:00', '10:00', '14:00', '18:00', '22:00'];
          break;
        default:
          _times = ['08:00'];
      }
    });
  }

  /// Save medicine to Firestore and schedule notifications
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Create Medicine object with a random unique ID
    final medicine = Medicine(
      id:        const Uuid().v4(),
      name:      _nameController.text.trim(),
      dosage:    _dosageController.text.trim(),
      frequency: _frequency,
      times:     List.from(_times),
      notes:     _notesController.text.trim().isEmpty
                     ? null
                     : _notesController.text.trim(),
      startDate: DateTime.now(),
    );

    try {
      // Save to cloud database
      await FirestoreService.addMedicine(medicine);
      // Schedule daily notifications for each reminder time
      await NotificationService.scheduleMedicineReminder(medicine);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Medicine added & reminders set!'),
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
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medicine'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Medicine Name ───────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name *',
                  hintText: 'e.g. Paracetamol, Metformin',
                  prefixIcon: Icon(Icons.medication_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Medicine name is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Dosage ──────────────────────────────────────────────────
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage *',
                  hintText: 'e.g. 500mg, 1 tablet, 10ml',
                  prefixIcon: Icon(Icons.scale_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Dosage is required' : null,
              ),
              const SizedBox(height: 16),

              // ── Frequency Dropdown ──────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: _frequencies
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => _onFrequencyChanged(v!),
              ),
              const SizedBox(height: 24),

              // ── Reminder Times ──────────────────────────────────────────
              Text(
                '⏰  Reminder Times',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap any time to change it',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 10),

              // One tile per reminder time
              ..._times.asMap().entries.map((entry) {
                final index = entry.key;
                final time  = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    leading: const Icon(Icons.alarm_outlined),
                    title: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text('Reminder ${index + 1}'),
                    trailing: const Icon(Icons.edit_outlined, size: 18),
                    onTap: () => _pickTime(index),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // ── Notes ───────────────────────────────────────────────────
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. Take after meals, avoid dairy',
                  prefixIcon: Icon(Icons.note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Save Button ─────────────────────────────────────────────
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.alarm_add_rounded),
                  label: const Text(
                    'Save & Set Reminders',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Helpful note for beginners
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notifications will fire daily at your set times, even when the app is closed.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
