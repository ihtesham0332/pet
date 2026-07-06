import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _loading = false;

  Future<void> _upgrade(String tier) async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiEndpoints.subscribe, data: {'tier': tier});
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upgraded to $tier!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upgrade failed: $e')),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('Downgrade to the free tier? You will lose access to premium features.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep Plan')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.emergencyRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Downgrade'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(ApiEndpoints.cancelSubscription);
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downgraded to Free tier')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed: $e')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final tier = auth.user?.subscriptionTier ?? 'free';

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PlanCard(
            name: 'Free',
            price: '\$0',
            features: const [
              '1 pet profile',
              '3 symptom checks / month',
              'Basic health tracking',
              'Emergency alerts',
            ],
            isCurrent: tier == 'free',
            onUpgrade: null,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Premium',
            price: '\$9.99',
            period: '/month',
            features: const [
              'Up to 5 pets',
              '30 symptom checks / month',
              'Telehealth consultations',
              'Weight tracking & charts',
              'Vaccination reminders',
              'Priority support',
            ],
            isCurrent: tier == 'premium',
            onUpgrade: tier == 'free' ? () => _upgrade('premium') : null,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Pro',
            price: '\$19.99',
            period: '/month',
            features: const [
              'Unlimited pets',
              'Unlimited symptom checks',
              'All Premium features',
              'Advanced AI diagnostics',
              'Multi-pet dashboard',
              'Family sharing (up to 5 users)',
            ],
            isCurrent: tier == 'pro',
            onUpgrade: tier != 'pro' ? () => _upgrade('pro') : null,
            color: AppTheme.infoBlue,
          ),
          if (tier != 'free') ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _cancel,
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.emergencyRed),
                label: Text(
                  _loading ? 'Processing...' : 'Cancel Subscription',
                  style: const TextStyle(color: AppTheme.emergencyRed),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.emergencyRed),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String? period;
  final List<String> features;
  final bool isCurrent;
  final VoidCallback? onUpgrade;
  final Color color;

  const _PlanCard({
    required this.name,
    required this.price,
    this.period,
    required this.features,
    required this.isCurrent,
    this.onUpgrade,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isCurrent
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
                if (isCurrent)
                  Chip(
                    label: const Text('Current', style: TextStyle(fontSize: 11)),
                    backgroundColor: color.withOpacity(0.15),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(price,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    )),
                if (period != null)
                  Text(period!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )),
            if (onUpgrade != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: onUpgrade,
                  child: Text('Upgrade to $name'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
