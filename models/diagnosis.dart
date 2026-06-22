// models/diagnosis.dart  —  Doctor-added diagnosis record

class Diagnosis {
  final String id;
  final String condition;       // e.g. "Type 2 Diabetes"
  final String doctorName;      // e.g. "Dr. Sharma"
  final String? clinicName;     // e.g. "Sahyadri Hospital"
  final String? notes;          // doctor's notes
  final List<String> medicines; // prescribed medicine names
  final DateTime date;
  final bool visibleToPatient;  // doctor can mark private notes

  Diagnosis({
    required this.id,
    required this.condition,
    required this.doctorName,
    this.clinicName,
    this.notes,
    required this.medicines,
    required this.date,
    this.visibleToPatient = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'condition': condition, 'doctorName': doctorName,
    'clinicName': clinicName, 'notes': notes, 'medicines': medicines,
    'date': date.toIso8601String(), 'visibleToPatient': visibleToPatient,
  };

  factory Diagnosis.fromMap(Map<String, dynamic> m) => Diagnosis(
    id: m['id'], condition: m['condition'], doctorName: m['doctorName'],
    clinicName: m['clinicName'], notes: m['notes'],
    medicines: List<String>.from(m['medicines'] ?? []),
    date: DateTime.parse(m['date']),
    visibleToPatient: m['visibleToPatient'] ?? true,
  );
}
