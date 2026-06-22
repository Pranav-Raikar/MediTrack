// ─────────────────────────────────────────────────────────────────────────────
// screens/premium/premium_screen.dart  —  Upgrade to Premium
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/subscription_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isPremium  = false;
  bool _isLoading  = true;
  int  _selected   = 0; // 0 = patient plan, 1 = clinic plan

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final premium = await SubscriptionService.isPremium();
    setState(() { _isPremium = premium; _isLoading = false; });
  }

  void _subscribe() {
    final user = FirebaseAuth.instance.currentUser!;
    if (_selected == 0) {
      SubscriptionService.openPremiumCheckout(userEmail: user.email ?? '');
    } else {
      SubscriptionService.openClinicCheckout(
        clinicEmail: user.email ?? '',
        clinicName:  'My Clinic',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isPremium
              ? _AlreadyPremium()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.workspace_premium,
                                  size: 40, color: Colors.amber),
                            ),
                            const SizedBox(height: 12),
                            Text('Unlock MediTrack Pro',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('Choose the plan that suits you',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Plan selector
                      _PlanCard(
                        selected: _selected == 0,
                        title: 'Patient Premium',
                        price: '₹99 / month',
                        color: const Color(0xFF1565C0),
                        features: const [
                          'No ads — clean experience',
                          'AI health summary & insights',
                          'Export PDF health report',
                          'Unlimited vitals history',
                          'Drug interaction checker',
                        ],
                        onTap: () => setState(() => _selected = 0),
                      ),
                      const SizedBox(height: 12),
                      _PlanCard(
                        selected: _selected == 1,
                        title: 'Clinic / Hospital Plan',
                        price: '₹2,999 / month',
                        color: const Color(0xFF4527A0),
                        badge: 'B2B',
                        features: const [
                          'Doctor web portal dashboard',
                          'See all linked patient records',
                          'Add diagnoses & prescriptions',
                          'AI patient summary before visits',
                          'Up to 5 doctors per clinic',
                          'All data in one place — forever',
                        ],
                        onTap: () => setState(() => _selected = 1),
                      ),
                      const SizedBox(height: 28),

                      // Subscribe button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _subscribe,
                          icon: const Icon(Icons.lock_open_rounded),
                          label: Text(
                            'Subscribe — ${_selected == 0 ? '₹99/mo' : '₹2,999/mo'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _selected == 0
                                ? const Color(0xFF1565C0)
                                : const Color(0xFF4527A0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Powered by Razorpay  •  Cancel anytime',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Trust badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _TrustBadge(icon: Icons.lock_outline, label: 'Secure\npayment'),
                          _TrustBadge(icon: Icons.cancel_outlined, label: 'Cancel\nanytime'),
                          _TrustBadge(icon: Icons.support_agent, label: '24/7\nsupport'),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ─── Plan Card ───────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final bool selected;
  final String title, price;
  final Color color;
  final List<String> features;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({
    required this.selected, required this.title, required this.price,
    required this.color, required this.features, required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.06) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: selected ? 2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: selected ? color : null)),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge!,
                        style: TextStyle(
                            fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(price,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: selected ? color : Colors.grey),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

class _AlreadyPremium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          Text('You are a Premium member!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('All features unlocked',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
