// ─────────────────────────────────────────────────────────────────────────────
// services/ai_service.dart  —  Claude AI Health Summaries
//
// This calls the Anthropic Claude API via a Firebase Cloud Function
// (we never put API keys in the Flutter app directly — security rule!)
//
// FEATURES:
//  - Patient health summary for doctor (before visit)
//  - Drug interaction checker
//  - Vitals anomaly detector
//  - Diagnosis suggestions (NOT a replacement for doctor — just a hint)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine.dart';
import '../models/vital.dart';
import '../models/diagnosis.dart';

class AiService {
  // This URL points to your Firebase Cloud Function (ai_summary)
  // Replace with your actual Firebase project URL after deployment
  static const _functionUrl =
      'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/generateHealthSummary';

  /// Generate a full health summary for a patient
  /// Used in: doctor portal (before a visit) + premium patient view
  static Future<String> generatePatientSummary({
    required List<Medicine> medicines,
    required List<Vital> recentVitals,
    required List<Diagnosis> diagnoses,
    required String patientName,
    required int? patientAge,
  }) async {
    // Build a plain-text summary of the patient's data to send to Claude
    final medicineList = medicines
        .map((m) => '- ${m.name} ${m.dosage} ${m.frequency}')
        .join('\n');

    final vitalsList = recentVitals
        .take(10)
        .map((v) => '- ${v.typeName}: ${v.displayValue}')
        .join('\n');

    final diagnosisList = diagnoses
        .map((d) => '- ${d.condition} (${d.date.year}): ${d.notes ?? ""}')
        .join('\n');

    final prompt = '''
You are a clinical AI assistant. Summarise the following patient data concisely 
for a doctor before a consultation. Be factual, clinical, and brief (under 200 words).
Flag any concerns about drug interactions or abnormal vitals.

Patient: $patientName${patientAge != null ? ', Age $patientAge' : ''}

CURRENT MEDICINES:
$medicineList

RECENT VITALS:
$vitalsList

PAST DIAGNOSES:
$diagnosisList

Provide:
1. Brief clinical summary
2. Any red flags or concerns
3. Suggested discussion points for the doctor

Important: Always end with "This summary is AI-generated and must not replace clinical judgment."
''';

    return await _callClaudeViaFunction(prompt);
  }

  /// Check if any two medicines in the list might interact
  static Future<String> checkDrugInteractions(List<Medicine> medicines) async {
    if (medicines.length < 2) {
      return 'Add at least 2 medicines to check for interactions.';
    }
    final names = medicines.map((m) => m.name).join(', ');
    final prompt = '''
Check for potential drug interactions between: $names.
List any known or possible interactions briefly.
If none are known, say "No significant interactions found."
Keep it under 100 words, plain language.
''';
    return await _callClaudeViaFunction(prompt);
  }

  /// Analyse vitals and flag anomalies
  static Future<String> analyseVitals(List<Vital> vitals) async {
    if (vitals.isEmpty) return 'No vitals data to analyse yet.';
    final data = vitals
        .take(7)
        .map((v) => '${v.typeName}: ${v.displayValue}')
        .join(', ');
    final prompt = '''
Analyse these recent health readings: $data
In 2-3 sentences, tell the patient:
1. Whether readings look normal
2. Any specific concern to watch
3. One lifestyle tip
Keep it friendly, not scary. Max 80 words.
''';
    return await _callClaudeViaFunction(prompt);
  }

  /// Internal: calls the Firebase Cloud Function which calls Claude API
  /// The API key lives in Cloud Functions (server-side) — never in app code
  static Future<String> _callClaudeViaFunction(String prompt) async {
    try {
      // Get the current user's auth token to verify they're logged in
      final token =
          await FirebaseAuth.instance.currentUser?.getIdToken() ?? '';

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'] ?? 'Could not generate summary.';
      } else {
        return 'AI service temporarily unavailable. Please try again.';
      }
    } catch (e) {
      return 'Could not connect to AI service. Check your internet connection.';
    }
  }
}
