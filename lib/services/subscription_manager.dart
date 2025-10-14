import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionManager {
  static final _client = Supabase.instance.client;

  // Constants
  static int _freeDailyLimit = 3; // Default value, will be fetched from backend
  static const double monthlyPrice = 4.99;
  static const double yearlyPrice = 34.99;

  // Getter for free daily limit
  static int get freeDailyLimit => _freeDailyLimit;

  // Fetch free daily limit from backend configuration
  static Future<void> fetchFreeDailyLimit() async {
    try {
      final response = await _client
          .from('app_config')
          .select('value')
          .eq('key', 'free_daily_scan_limit')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        // Parse the value from JSONB
        final value = response['value'];
        if (value is String) {
          _freeDailyLimit = int.tryParse(value) ?? 3;
        } else if (value is int) {
          _freeDailyLimit = value;
        }
      }
    } catch (error) {
      _freeDailyLimit = 3; // Fallback to default
    }
  }

  // Get current user's subscription info
  static Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('user_subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (error) {
      return null;
    }
  }

  // Check if user has active Traveler Pass (including cancelling status)
  static Future<bool> hasTravelerPass() async {
    try {
      final subscription = await getCurrentSubscription();
      return subscription?['subscription_type'] == 'traveler_pass' &&
          (subscription?['status'] == 'active' ||
              subscription?['status'] == 'cancelling');
    } catch (error) {
      return false;
    }
  }

  // Get today's usage for the user
  static Future<Map<String, dynamic>?> getTodayUsage() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _client
          .from('daily_usage')
          .select()
          .eq('user_id', user.id)
          .eq('usage_date', today)
          .maybeSingle();

      return response;
    } catch (error) {
      return null;
    }
  }

  // Check if user can scan (has remaining scans or traveler pass)
  static Future<bool> canScan() async {
    try {
      // Check if user has Traveler Pass (unlimited scans)
      if (await hasTravelerPass()) {
        return true;
      }

      // Check daily usage for free users
      final usage = await getTodayUsage();
      final scansUsed = usage?['scans_used'] ?? 0;

      return scansUsed < freeDailyLimit;
    } catch (error) {
      return false;
    }
  }

  // Get remaining scans for today (for free users)
  static Future<int> getRemainingScans() async {
    try {
      if (await hasTravelerPass()) {
        return -1; // Unlimited
      }

      final usage = await getTodayUsage();
      final scansUsed = usage?['scans_used'] ?? 0;

      return (freeDailyLimit - scansUsed).clamp(0, freeDailyLimit).toInt();
    } catch (error) {
      return 0;
    }
  }

  // Increment scan usage
  static Future<bool> incrementScanUsage({
    String? targetLanguage,
    Map<String, dynamic>? webhookResponse,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Don't track usage for Traveler Pass users
      if (await hasTravelerPass()) {
        return true;
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      // Get current usage
      final currentUsage = await getTodayUsage();
      final currentScans = currentUsage?['scans_used'] ?? 0;

      // Upsert with incremented value to daily_usage table
      await _client.from('daily_usage').upsert({
        'user_id': user.id,
        'usage_date': today,
        'scans_used': currentScans + 1,
      }, onConflict: 'user_id,usage_date');

      // Also track in usage_tracking table for analytics
      try {
        // Build comprehensive metadata for analytics
        final metadata = <String, dynamic>{'scan_count': currentScans + 1};

        // Add target language if provided
        if (targetLanguage != null) {
          metadata['target_language'] = targetLanguage;
        }

        // Add webhook response data if provided
        if (webhookResponse != null) {
          metadata['webhook_response'] = webhookResponse;
          // Also extract useful summary data
          if (webhookResponse['output'] != null) {
            final items = webhookResponse['output'] as List?;
            metadata['items_count'] = items?.length ?? 0;
            metadata['has_recommendations'] = items?.any(
                  (item) => item is Map && item['isRecommended'] == true,
                ) ??
                false;
          }
        }

        await _client.from('usage_tracking').insert({
          'user_id': user.id,
          'action_type': 'scan',
          'metadata': metadata,
          // created_at is auto-generated by the database
        });
      } catch (trackingError) {
        // Don't fail the whole operation if analytics tracking fails
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  // Activate Traveler Pass subscription
  static Future<bool> activateTravelerPass({
    required String planDuration, // 'monthly' or 'yearly'
    String? transactionId,
    String? platform,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final endDate = planDuration == 'yearly'
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 30));

      await _client.from('user_subscriptions').upsert({
        'user_id': user.id,
        'subscription_type': 'traveler_pass',
        'status': 'active',
        'plan_duration': planDuration,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'platform': platform,
        'transaction_id': transactionId,
      });

      return true;
    } catch (error) {
      return false;
    }
  }

  // Get subscription display info
  static Future<Map<String, dynamic>> getSubscriptionInfo() async {
    try {
      final subscription = await getCurrentSubscription();
      final remainingScans = await getRemainingScans();

      // Check if subscription exists AND is Traveler Pass AND has valid active/cancelling status
      if (subscription != null &&
          subscription['subscription_type'] == 'traveler_pass' &&
          subscription['status'] != null &&
          (subscription['status'] == 'active' ||
              subscription['status'] == 'cancelling')) {
        // Show Traveler Pass for both active and cancelling status
        final isCancelling = subscription['status'] == 'cancelling';
        return {
          'plan': 'Traveler Pass',
          'status': isCancelling ? 'Cancelling' : 'Active',
          'scans': 'Unlimited',
          'isActive': true,
          'isCancelling': isCancelling,
          'planDuration': subscription['plan_duration'] ?? 'monthly',
          'endDate': subscription['end_date'],
          'stripeSubscriptionId': subscription['stripe_subscription_id'],
        };
      } else {
        return {
          'plan': 'Free Plan',
          'status': 'Active',
          'scans': '$remainingScans/$freeDailyLimit today',
          'isActive': false,
          'isCancelling': false,
        };
      }
    } catch (error) {
      return {
        'plan': 'Free Plan',
        'status': 'Active',
        'scans': '0/$freeDailyLimit today',
        'isActive': false,
        'isCancelling': false,
      };
    }
  }

  // Cancel subscription
  static Future<bool> cancelSubscription() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Get current subscription
      final subscription = await getCurrentSubscription();
      if (subscription == null) {
        return false;
      }

      final stripeSubscriptionId = subscription['stripe_subscription_id'];
      if (stripeSubscriptionId == null) {
        return false;
      }

      // Call Supabase edge function to cancel subscription in Stripe
      final response = await _client.functions.invoke(
        'cancel-subscription',
        body: {'subscriptionId': stripeSubscriptionId},
      );

      if (response.status == 200) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  // Resume subscription (remove cancellation)
  static Future<bool> resumeSubscription() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Get current subscription
      final subscription = await getCurrentSubscription();
      if (subscription == null) {
        return false;
      }

      if (subscription['status'] != 'cancelling') {
        return false;
      }

      final stripeSubscriptionId = subscription['stripe_subscription_id'];
      if (stripeSubscriptionId == null) {
        return false;
      }

      // Call Supabase edge function to resume subscription in Stripe
      final response = await _client.functions.invoke(
        'resume-subscription',
        body: {'subscriptionId': stripeSubscriptionId},
      );

      if (response.status == 200) {
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }
}
