import 'package:flutter/material.dart';

enum BillingCycle { monthly, annually }

class UpgradeView extends StatefulWidget {
  final Future<void> Function(String priceId) onCheckout;

  const UpgradeView({super.key, required this.onCheckout});

  @override
  State<UpgradeView> createState() => _UpgradeViewState();
}

class _UpgradeViewState extends State<UpgradeView> {
  BillingCycle _selectedCycle = BillingCycle.annually;
  bool _isCheckingOut = false;

  @override
  Widget build(BuildContext context) {
    final isAnnually = _selectedCycle == BillingCycle.annually;
    // Replace with your actual Price IDs
    final priceId = isAnnually
        ? 'price_1SFAhOFQWjnlvKIaG8GSOjEa'
        : 'price_1SFAdwFQWjnlvKIaanNQoV5v';
    final priceString = isAnnually ? '\$34.99/year' : '\$4.99/month';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Upgrade to Traveler Pass',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Get unlimited scans and an ad-free experience.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ToggleButtons(
            isSelected: [!isAnnually, isAnnually],
            onPressed: (index) {
              setState(() {
                _selectedCycle =
                    index == 1 ? BillingCycle.annually : BillingCycle.monthly;
              });
            },
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            color: Colors.grey,
            fillColor: Theme.of(context).colorScheme.primary,
            splashColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            borderWidth: 0,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Monthly'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Annually'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          priceString,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isAnnually) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Save 40%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCheckingOut
                ? null
                : () async {
                    print('🔵 Upgrade button clicked with priceId: $priceId');
                    setState(() {
                      _isCheckingOut = true;
                    });
                    try {
                      print('🔵 Calling onCheckout function...');
                      await widget.onCheckout(priceId);
                      print('🔵 onCheckout function completed');
                    } catch (error) {
                      print('🔴 Error in onCheckout: $error');
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isCheckingOut = false;
                        });
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: _isCheckingOut
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Get Traveler Pass',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }
}
