// ════════════════════════════════════════════════════════════════
//  vital.dart  –  Blueprint for a Health Vitals entry
//  Stores BP, blood sugar, and weight readings
// ════════════════════════════════════════════════════════════════

class Vital {
  final String id;
  final double bloodPressureSystolic;   // Upper BP reading e.g. 120
  final double bloodPressureDiastolic;  // Lower BP reading e.g. 80
  final double bloodSugar;              // mg/dL e.g. 95
  final double weight;                  // in kg
  final DateTime recordedAt;            // When this was measured

  Vital({
    required this.id,
    required this.bloodPressureSystolic,
    required this.bloodPressureDiastolic,
    required this.bloodSugar,
    required this.weight,
    required this.recordedAt,
  });

  // ── Converts object to map for Firestore ───────────────────
  Map<String, dynamic> toMap() {
    return {
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'bloodSugar': bloodSugar,
      'weight': weight,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  // ── Creates object from Firestore map ──────────────────────
  factory Vital.fromMap(String id, Map<String, dynamic> map) {
    return Vital(
      id: id,
      bloodPressureSystolic: (map['bloodPressureSystolic'] ?? 0).toDouble(),
      bloodPressureDiastolic: (map['bloodPressureDiastolic'] ?? 0).toDouble(),
      bloodSugar: (map['bloodSugar'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      recordedAt: DateTime.parse(map['recordedAt']),
    );
  }

  // ── Helper: Returns a readable BP string ──────────────────
  String get bpString =>
      '${bloodPressureSystolic.toInt()}/${bloodPressureDiastolic.toInt()}';
}
