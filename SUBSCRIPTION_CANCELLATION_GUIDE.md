# Subscription Cancellation Implementation Guide

## Overview

This guide covers the implementation of subscription management improvements, including:

1. Fixing the delayed subscription display issue
2. Adding subscription cancellation functionality for Traveler Pass users

## Changes Made

### 1. Profile Screen Updates (`lib/views/profile_screen.dart`)

#### Issue 1 Fix: Loading State

- Added `_isLoadingSubscription` boolean flag to track subscription loading state
- Modified `_buildSubscriptionCard()` to show a loading skeleton while fetching subscription data
- This prevents showing "Free Plan" before the actual subscription loads

#### Issue 2 Fix: Cancellation Feature

- Added `_showTravelerPassManagement()` method to display subscription details for active users
- Added `_showCancelConfirmation()` method with double confirmation dialog
- Added `_cancelSubscription()` method to handle the cancellation flow
- Added helper methods:
  - `_buildBenefitRow()` - displays subscription benefits
  - `_formatDate()` - formats renewal dates

### 2. Subscription Manager Updates (`lib/services/subscription_manager.dart`)

#### Enhanced Subscription Info

- Updated `getSubscriptionInfo()` to return additional fields:
  - `planDuration` - monthly or yearly
  - `endDate` - subscription end/renewal date
  - `stripeSubscriptionId` - for cancellation

#### Cancellation Method

- Added `cancelSubscription()` method that:
  - Validates user authentication
  - Retrieves current subscription
  - Calls the Supabase edge function to cancel in Stripe
  - Returns success/failure status

### 3. New Supabase Edge Function (`supabase/functions/cancel-subscription/`)

Created a new edge function to handle subscription cancellation:

- Authenticates the user via JWT
- Verifies subscription ownership
- Cancels subscription in Stripe (at period end)
- Updates Supabase database with "cancelling" status

### 4. Webhook Updates (`supabase/functions/stripe-webhook/index.ts`)

Enhanced the `customer.subscription.updated` handler to:

- Detect when `cancel_at_period_end` is true
- Set status to "cancelling" in the database
- Maintain user access until the end of billing period

## Deployment Steps

### Step 1: Deploy the Edge Function

```bash
# Deploy the cancel-subscription function
supabase functions deploy cancel-subscription

# Verify deployment
supabase functions list
```

### Step 2: Update Stripe Webhook

The webhook handler has been updated to handle cancellation status. Redeploy it:

```bash
supabase functions deploy stripe-webhook
```

### Step 3: Database Schema (Optional)

If you want to track cancellation requests, you can add a column to track when cancellation was requested:

```sql
-- Optional: Add cancellation tracking
ALTER TABLE user_subscriptions
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

-- Update the column when status changes to 'cancelling'
CREATE OR REPLACE FUNCTION update_cancelled_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'cancelling' AND OLD.status != 'cancelling' THEN
    NEW.cancelled_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_cancelled_at
  BEFORE UPDATE ON user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_cancelled_at();
```

### Step 4: Test the Implementation

1. **Test Loading State:**

   - Navigate to Profile Screen
   - Verify no "Free Plan" flash before actual plan loads
   - Should see loading skeleton instead

2. **Test Traveler Pass Management:**

   - As a Traveler Pass user, click on subscription card
   - Verify subscription details are displayed correctly
   - Check that renewal date is shown

3. **Test Cancellation Flow:**
   - Click "Cancel Subscription" button
   - Verify first confirmation dialog appears
   - Click "Cancel Subscription" in dialog
   - Verify success message appears
   - Check that subscription status updates to "cancelling"
   - Verify user still has access until end of period

## What Happens When User Cancels

### Immediate Effects:

1. Stripe subscription is updated with `cancel_at_period_end: true`
2. Database status changes to "cancelling"
3. User sees confirmation message
4. User retains full access until end of billing period

### At End of Billing Period:

1. Stripe automatically cancels the subscription
2. Webhook receives `customer.subscription.deleted` event
3. Database status changes to "inactive"
4. User loses access to Traveler Pass features
5. User reverts to Free Plan (3 scans per day)

## Stripe Dashboard Verification

To verify cancellation in Stripe:

1. Go to Stripe Dashboard → Customers
2. Find the customer by email
3. Click on their subscription
4. You should see "Cancels on [date]" label
5. Status should show as "Active" until cancellation date

## Supabase Database Verification

Check the subscription status:

```sql
SELECT
  user_id,
  subscription_type,
  status,
  plan_duration,
  end_date,
  stripe_subscription_id
FROM user_subscriptions
WHERE status = 'cancelling';
```

## Handling Edge Cases

### User Wants to Reactivate

If a user changes their mind before the period ends, you'll need to add a "Reactivate" feature:

```dart
// Add to subscription_manager.dart
static Future<bool> reactivateSubscription() async {
  // Call Stripe to remove cancel_at_period_end
  // Update database status back to 'active'
}
```

Then call Stripe API:

```typescript
await stripe.subscriptions.update(subscriptionId, {
  cancel_at_period_end: false,
});
```

### Failed Cancellation

If cancellation fails:

- User sees error message
- Subscription remains active
- User can try again or contact support

### Network Issues

- The app handles network errors gracefully
- Shows appropriate error messages
- User can retry the operation

## Testing Checklist

- [ ] Free user sees loading skeleton, then "Free Plan"
- [ ] Traveler Pass user sees loading skeleton, then "Traveler Pass"
- [ ] Clicking subscription card shows appropriate modal
- [ ] Free users see upgrade options
- [ ] Traveler Pass users see subscription details
- [ ] Cancellation button is visible for Traveler Pass users
- [ ] First confirmation dialog appears
- [ ] Second confirmation is required
- [ ] Success message appears after cancellation
- [ ] Subscription status updates in database
- [ ] User retains access until period end
- [ ] Stripe dashboard shows cancellation
- [ ] Webhook handles status updates correctly

## Support Considerations

When users contact support about cancellations:

1. **Check Stripe Dashboard:**

   - Verify cancellation status
   - Check cancellation date
   - Confirm no billing issues

2. **Check Supabase Database:**

   - Verify status is "cancelling" or "inactive"
   - Check end_date for access expiration
   - Review transaction history

3. **Common Questions:**
   - "When will I lose access?" → End of current billing period
   - "Will I get a refund?" → No, access continues until period end
   - "Can I reactivate?" → Yes, before the cancellation date (requires feature implementation)
   - "What happens to my data?" → Data is retained, just access is limited

## Future Enhancements

Consider adding:

1. Reactivation feature
2. Cancellation reason tracking
3. Win-back campaigns for cancelled users
4. Prorated refunds (if business model allows)
5. Pause subscription feature
6. Downgrade to different plan option

## Troubleshooting

### Cancellation Not Working

1. Check Supabase logs: `supabase functions logs cancel-subscription`
2. Verify Stripe API key is correct
3. Check user has valid subscription
4. Verify JWT token is being passed correctly

### Status Not Updating

1. Check webhook is receiving events
2. Verify webhook secret is correct
3. Check Supabase RLS policies allow updates
4. Review webhook logs for errors

### User Still Charged After Cancellation

1. Verify `cancel_at_period_end` is true in Stripe
2. Check if cancellation happened before billing date
3. Review Stripe subscription timeline
4. Contact Stripe support if needed
