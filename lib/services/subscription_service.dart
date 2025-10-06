import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  static final _client = Supabase.instance.client;

  // Get current user's subscription status
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

  // Check if user has active subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      final subscription = await getCurrentSubscription();
      return subscription?['status'] == 'active';
    } catch (error) {
      debugPrint('Error checking subscription status: $error');
      return false;
    }
  }

  // Update subscription status
  static Future<bool> updateSubscriptionStatus({
    required String status,
    DateTime? startDate,
    DateTime? endDate,
    String? platform,
    String? transactionId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (startDate != null) {
        updateData['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
      if (platform != null) updateData['platform'] = platform;
      if (transactionId != null) updateData['transaction_id'] = transactionId;

      await _client
          .from('user_subscriptions')
          .update(updateData)
          .eq('user_id', user.id);

      return true;
    } catch (error) {
      debugPrint('Error updating subscription: $error');
      return false;
    }
  }

  // Track usage for analytics
  static Future<void> trackUsage({
    required String actionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('usage_tracking').insert({
        'user_id': user.id,
        'action_type': actionType,
        'metadata': metadata,
      });
    } catch (error) {
      debugPrint('Error tracking usage: $error');
    }
  }

  // Get usage statistics
  static Future<List<Map<String, dynamic>>> getUsageStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('usage_tracking')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error getting usage stats: $error');
      return [];
    }
  }
}
