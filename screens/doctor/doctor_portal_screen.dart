import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../models/medicine.dart';
import '../../models/vital.dart';
import '../../models/diagnosis.dart';
import '../../services/ai_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// screens/doctor/doctor_portal_screen.dart  —  Doctor Web Dashboard
//
// Doctors see all linked patients, their records, and AI summaries.
// Patients link a doctor by sharing a 6-digit code from the AI insights screen.
// ─────────────────────────────────────────────────────────────────────────────

class DoctorPortalScreen extends StatefulWidget {
  const DoctorPortalScreen({super.key});

  @override
  State<DoctorPortalScreen> createState() => _DoctorPortalScreenState();
}

class _DoctorPortalScreenState extends State<DoctorPortalScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedPatientId;
  String? _selectedPatientName;
  String  _aiSummary   = '';
  bool    _loadingAI   = false;
  late TabController _tabController;

  String get _doctorUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Stream of patients linked to this doctor
  Stream<List<Map<String, dynamic>>> get _patientsStream {
    return FirebaseFirestore.instance
        .collection('doctors')
        .doc(_doctorUid)
        .collection('patients')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> _fetchAISummary() async {
    if (_selectedPatientId == null) return;
    setState(() => _loadingAI = true);

    try {
      final medsSnap = await FirebaseFirestore.instance
          .collection('users').doc(_selectedPatientId).collection('medicines').get();
      final vitalsSnap = await FirebaseFirestore.instance
          .collection('users').doc(_selectedPatientId).collection('vitals')
          .orderBy('recordedAt', descending: true).limit(10).get();
      final diagSnap = await FirebaseFirestore.instance
          .collection('users').doc(_selectedPatientId).collection('diagnoses').get();

      final meds   = medsSnap.docs.map((d)   => Medicine.fromMap(d.data())).toList();
      final vitals = vitalsSnap.docs.map((d)  => Vital.fromMap(d.data())).toList();
      final diags  = diagSnap.docs.map((d)    => Diagnosis.fromMap(d.data())).toList();

      final summary = await AiService.generatePatientSummary(
        medicines:    meds,
        recentVitals: vitals,
        diagnoses:    diags,
        patientName:  _selectedPatientName ?? 'Patient',
        patientAge:   null,
      );
      setState(() => _aiSummary = summary);
    } finally {
      setState(() => _loadingAI = false);
    }
  }

  Future<void> _addDiagnosis() async {
    final condCtrl  = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Diagnosis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: condCtrl,
              decoration: const InputDecoration(
                labelText: 'Condition *',
                hintText: 'e.g. Type 2 Diabetes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Clinical notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (condCtrl.text.trim().isEmpty) return;
              final doctorName =
                  FirebaseAuth.instance.currentUser?.displayName ?? 'Doctor';

              final diag = Diagnosis(
                id:          const Uuid().v4(),
                condition:   condCtrl.text.trim(),
                doctorName:  doctorName,
                notes:       notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                medicines:   [],
                date:        DateTime.now(),
              );

              // Write to patient's Firestore so they can see it too
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_selectedPatientId)
                  .collection('diagnoses')
                  .doc(diag.id)
                  .set(diag.toMap());

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [

          // ── LEFT SIDEBAR: patient list ────────────────────────────────
          Container(
            width: 260,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Column(
              children: [
                // Doctor header
                Container(
                  padding: const EdgeInsets.all(18),
                  color: theme.colorScheme.primary,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.local_hospital_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Doctor Portal',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(
                            FirebaseAuth.instance.currentUser?.email ?? '',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Patient list header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  child: Row(
                    children: [
                      Text('My Patients',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined),
                        tooltip: 'Link new patient',
                        onPressed: _showLinkDialog,
                      ),
                    ],
                  ),
                ),

                // Patient list stream
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _patientsStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final patients = snapshot.data!;
                      if (patients.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No patients yet.\nTap + to link one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (_, i) {
                          final p = patients[i];
                          final selected = _selectedPatientId == p['uid'];
                          return ListTile(
                            selected: selected,
                            selectedTileColor: theme.colorScheme.primaryContainer,
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              child: Text(
                                (p['name'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(color: theme.colorScheme.secondary),
                              ),
                            ),
                            title: Text(p['name'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(p['email'] ?? '',
                                style: const TextStyle(fontSize: 12)),
                            onTap: () => setState(() {
                              _selectedPatientId   = p['uid'];
                              _selectedPatientName = p['name'];
                              _aiSummary = '';
                              _tabController.index = 0;
                            }),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── RIGHT: patient detail ─────────────────────────────────────
          Expanded(
            child: _selectedPatientId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 14),
                        Text('Select a patient to view their records',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : Column(
                    children: [

                      // Patient header bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(_selectedPatientName ?? 'Patient',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _loadingAI ? null : _fetchAISummary,
                              icon: _loadingAI
                                  ? const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.auto_awesome),
                              label: const Text('AI Summary'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _addDiagnosis,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Diagnosis'),
                            ),
                          ],
                        ),
                      ),

                      // AI Summary box
                      if (_aiSummary.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.auto_awesome,
                                    size: 15, color: Colors.purple),
                                const SizedBox(width: 6),
                                Text('AI Clinical Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSecondaryContainer,
                                    )),
                              ]),
                              const SizedBox(height: 8),
                              Text(_aiSummary,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSecondaryContainer,
                                      height: 1.5)),
                            ],
                          ),
                        ),

                      // Tabs
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Medicines'),
                          Tab(text: 'Vitals'),
                          Tab(text: 'Diagnoses'),
                        ],
                      ),

                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _PatientMedicines(patientId: _selectedPatientId!),
                            _PatientVitals(patientId: _selectedPatientId!),
                            _PatientDiagnoses(patientId: _selectedPatientId!),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showLinkDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Link a Patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ask the patient to tap "Get sharing code" in the AI Insights tab of their MediTrack app.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '6-digit patient code',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Link')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Patient record sub-widgets (read-only views for the doctor)
// ─────────────────────────────────────────────────────────────────────────────

class _PatientMedicines extends StatelessWidget {
  final String patientId;
  const _PatientMedicines({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(patientId).collection('medicines')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text('No medicines on record'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final m = Medicine.fromMap(
                snap.data!.docs[i].data() as Map<String, dynamic>);
            return ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!)),
              leading: CircleAvatar(
                backgroundColor: m.isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey[200],
                child: const Icon(Icons.medication_outlined),
              ),
              title: Text(m.name),
              subtitle: Text('${m.dosage} · ${m.frequency}'),
              trailing: Chip(
                label: Text(m.isActive ? 'Active' : 'Paused',
                    style: const TextStyle(fontSize: 11)),
                backgroundColor: m.isActive
                    ? Colors.green[50]
                    : Colors.grey[100],
              ),
            );
          },
        );
      },
    );
  }
}

class _PatientVitals extends StatelessWidget {
  final String patientId;
  const _PatientVitals({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(patientId).collection('vitals')
          .orderBy('recordedAt', descending: true).limit(20)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text('No vitals recorded yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, i) {
            final v = Vital.fromMap(
                snap.data!.docs[i].data() as Map<String, dynamic>);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(v.typeName[0],
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(v.displayValue,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(v.typeName),
              trailing: Text(
                '${v.recordedAt.day}/${v.recordedAt.month}/${v.recordedAt.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            );
          },
        );
      },
    );
  }
}

class _PatientDiagnoses extends StatelessWidget {
  final String patientId;
  const _PatientDiagnoses({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(patientId).collection('diagnoses')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text('No diagnoses on record'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final d = Diagnosis.fromMap(
                snap.data!.docs[i].data() as Map<String, dynamic>);
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.condition,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Dr. ${d.doctorName}  ·  '
                        '${d.date.day}/${d.date.month}/${d.date.year}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    if (d.notes != null) ...[
                      const SizedBox(height: 8),
                      Text(d.notes!,
                          style: const TextStyle(fontSize: 13, height: 1.5)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
