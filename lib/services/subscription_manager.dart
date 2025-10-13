import 'package:flutter/foundation.dart';
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
        debugPrint('✅ Fetched free daily limit from backend: $_freeDailyLimit');
      }
    } catch (error) {
      debugPrint('⚠️ Error fetching free daily limit, using default: $error');
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
      debugPrint('Error getting subscription: $error');
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
      debugPrint('Error checking traveler pass: $error');
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
      debugPrint('Error getting today usage: $error');
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
      debugPrint('Error checking can scan: $error');
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
      debugPrint('Error getting remaining scans: $error');
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
        debugPrint('No user found for scan tracking');
        return false;
      }

      // Don't track usage for Traveler Pass users
      if (await hasTravelerPass()) {
        debugPrint('User has Traveler Pass, skipping usage tracking');
        return true;
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      // Get current usage
      final currentUsage = await getTodayUsage();
      final currentScans = currentUsage?['scans_used'] ?? 0;

      debugPrint(
        'Current scans for $today: $currentScans, incrementing to ${currentScans + 1}',
      );

      // Upsert with incremented value to daily_usage table
      await _client.from('daily_usage').upsert({
        'user_id': user.id,
        'usage_date': today,
        'scans_used': currentScans + 1,
      }, onConflict: 'user_id,usage_date');
      debugPrint('✅ Updated daily_usage table: ${currentScans + 1} scans');

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
        debugPrint(
          '✅ Inserted into usage_tracking table with enhanced metadata',
        );
      } catch (trackingError) {
        debugPrint('⚠️ Failed to insert into usage_tracking: $trackingError');
        // Don't fail the whole operation if analytics tracking fails
      }

      debugPrint(
        'Successfully updated both tables with scan count: ${currentScans + 1}',
      );
      return true;
    } catch (error) {
      debugPrint('Error incrementing scan usage: $error');
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
      debugPrint('Error activating traveler pass: $error');
      return false;
    }
  }

  // Get subscription display info
  static Future<Map<String, dynamic>> getSubscriptionInfo() async {
    try {
      final subscription = await getCurrentSubscription();
      final remainingScans = await getRemainingScans();

      if (subscription != null &&
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
      debugPrint('Error getting subscription info: $error');
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
        debugPrint('No user found for cancellation');
        return false;
      }

      // Get current subscription
      final subscription = await getCurrentSubscription();
      if (subscription == null) {
        debugPrint('No subscription found to cancel');
        return false;
      }

      final stripeSubscriptionId = subscription['stripe_subscription_id'];
      if (stripeSubscriptionId == null) {
        debugPrint('No Stripe subscription ID found');
        return false;
      }

      // Call Supabase edge function to cancel subscription in Stripe
      final response = await _client.functions.invoke(
        'cancel-subscription',
        body: {'subscriptionId': stripeSubscriptionId},
      );

      if (response.status == 200) {
        debugPrint('Subscription cancelled successfully');
        return true;
      } else {
        debugPrint('Failed to cancel subscription: ${response.data}');
        return false;
      }
    } catch (error) {
      debugPrint('Error cancelling subscription: $error');
      return false;
    }
  }

  // Resume subscription (remove cancellation)
  static Future<bool> resumeSubscription() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('No user found for resuming subscription');
        return false;
      }

      // Get current subscription
      final subscription = await getCurrentSubscription();
      if (subscription == null) {
        debugPrint('No subscription found to resume');
        return false;
      }

      if (subscription['status'] != 'cancelling') {
        debugPrint('Subscription is not in cancelling state');
        return false;
      }

      final stripeSubscriptionId = subscription['stripe_subscription_id'];
      if (stripeSubscriptionId == null) {
        debugPrint('No Stripe subscription ID found');
        return false;
      }

      // Call Supabase edge function to resume subscription in Stripe
      final response = await _client.functions.invoke(
        'resume-subscription',
        body: {'subscriptionId': stripeSubscriptionId},
      );

      if (response.status == 200) {
        debugPrint('Subscription resumed successfully');
        return true;
      } else {
        debugPrint('Failed to resume subscription: ${response.data}');
        return false;
      }
    } catch (error) {
      debugPrint('Error resuming subscription: $error');
      return false;
    }
  }
}
