// ─────────────────────────────────────────────────────────────────────────────
// screens/ai/ai_insights_screen.dart  —  AI Health Insights (Premium only)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  String _vitalsAnalysis   = '';
  String _drugInteraction  = '';
  bool   _loadingVitals    = false;
  bool   _loadingDrugs     = false;

  Future<void> _analyseVitals() async {
    setState(() => _loadingVitals = true);
    final vitals = await FirestoreService.getVitals().first;
    final result = await AiService.analyseVitals(vitals);
    setState(() { _vitalsAnalysis = result; _loadingVitals = false; });
  }

  Future<void> _checkInteractions() async {
    setState(() => _loadingDrugs = true);
    final meds = await FirestoreService.getMedicines().first;
    final result = await AiService.checkDrugInteractions(meds);
    setState(() { _drugInteraction = result; _loadingDrugs = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('AI Health Insights'),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.workspace_premium, size: 14, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('Premium', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  // ── Vitals Analysis card ──────────────────────────────
                  _InsightCard(
                    icon: Icons.favorite_outline,
                    iconColor: Colors.red,
                    title: 'Vitals Analysis',
                    description: 'AI checks your recent readings for patterns and alerts',
                    onGenerate: _analyseVitals,
                    isLoading: _loadingVitals,
                    result: _vitalsAnalysis,
                  ),
                  const SizedBox(height: 16),

                  // ── Drug Interaction card ─────────────────────────────
                  _InsightCard(
                    icon: Icons.medication_outlined,
                    iconColor: Colors.orange,
                    title: 'Drug Interaction Check',
                    description: 'Checks if your medicines could interact with each other',
                    onGenerate: _checkInteractions,
                    isLoading: _loadingDrugs,
                    result: _drugInteraction,
                  ),
                  const SizedBox(height: 16),

                  // ── Share with Doctor banner ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Share with your doctor',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                'Generate a 6-digit code — your doctor enters it to see your full history.',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () => _showShareCode(context),
                          child: const Text('Share'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareCode(BuildContext context) {
    // In real app: generate random 6-digit code, save to Firestore under user doc
    // Doctor enters code → gets linked to patient
    final code = (100000 + DateTime.now().millisecond * 17 % 900000).toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your sharing code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with your doctor:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 8),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Code expires in 24 hours',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable insight card ────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, description;
  final VoidCallback onGenerate;
  final bool isLoading;
  final String result;

  const _InsightCard({
    required this.icon, required this.iconColor, required this.title,
    required this.description, required this.onGenerate,
    required this.isLoading, required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (result.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result, style: const TextStyle(fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onGenerate,
              icon: isLoading
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(isLoading ? 'Analysing...' : (result.isEmpty ? 'Generate insight' : 'Refresh')),
            ),
          ),
        ],
      ),
    );
  }
}
