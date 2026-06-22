// ─────────────────────────────────────────────────────────────────────────────
// screens/medicines/medicine_list_screen.dart  —  Medicines Tab
//
// FEATURES:
//  - Shows all medicines split into Active / Inactive sections
//  - Swipe left to delete a medicine
//  - Toggle switch to pause/resume reminders
//  - FAB (Floating Action Button) to add new medicine
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import 'add_medicine_screen.dart';

class MedicineListScreen extends StatelessWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Large collapsible app bar
          SliverAppBar.large(
            title: const Text('My Medicines'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add Medicine',
                onPressed: () => _goToAdd(context),
              ),
            ],
          ),

          // StreamBuilder rebuilds the list whenever Firestore data changes
          StreamBuilder<List<Medicine>>(
            stream: FirestoreService.getMedicines(),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Empty state
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No medicines added yet',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => _goToAdd(context),
                          child: const Text('Add Your First Medicine'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final medicines = snapshot.data!;
              final active   = medicines.where((m) => m.isActive).toList();
              final inactive = medicines.where((m) => !m.isActive).toList();

              return SliverList(
                delegate: SliverChildListDelegate([
                  // Active medicines
                  if (active.isNotEmpty) ...[
                    _sectionLabel(context, 'Active', theme.colorScheme.primary),
                    ...active.map((m) => _MedicineCard(medicine: m)),
                  ],
                  // Inactive medicines
                  if (inactive.isNotEmpty) ...[
                    _sectionLabel(context, 'Paused', Colors.grey),
                    ...inactive.map((m) => _MedicineCard(medicine: m)),
                  ],
                  const SizedBox(height: 100), // space above FAB
                ]),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
    );
  }

  void _goToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
    );
  }

  Widget _sectionLabel(BuildContext context, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MedicineCard  —  Individual medicine tile
// ─────────────────────────────────────────────────────────────────────────────
class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  const _MedicineCard({required this.medicine});

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isActive = medicine.isActive;

    return Dismissible(
      key: Key(medicine.id),
      direction: DismissDirection.endToStart, // swipe left to delete
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // Ask user to confirm before deleting
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Medicine?'),
            content: Text('Remove "${medicine.name}" from your list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        // Cancel notifications and delete from DB
        await NotificationService.cancelMedicineReminders(medicine.id);
        await FirestoreService.deleteMedicine(medicine.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${medicine.name} removed')),
          );
        }
      },

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Medicine icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? theme.colorScheme.primary : Colors.grey,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),

            // Name, dosage, times
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${medicine.dosage}  •  ${medicine.frequency}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  // Show each reminder time as a small chip
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: medicine.times
                        .map((t) => Chip(
                              label: Text(t,
                                  style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            // Toggle active/inactive
            Switch(
              value: isActive,
              onChanged: (val) async {
                final updated = medicine.copyWith(isActive: val);
                await FirestoreService.updateMedicine(updated);
                if (val) {
                  await NotificationService.scheduleMedicineReminder(updated);
                } else {
                  await NotificationService.cancelMedicineReminders(medicine.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
