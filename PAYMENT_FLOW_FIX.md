# Payment Flow Fix

## Issue

After successful Stripe payment, the user's subscription was not being updated from "Free Plan" to "Traveler Pass Plan" in the database.

## Root Causes Identified

1. **Wrong Database Table**: The Stripe webhook was inserting into a `subscriptions` table that doesn't exist, instead of the correct `user_subscriptions` table.

2. **Missing User ID**: The checkout session wasn't including the user's Supabase ID in metadata, so the webhook couldn't identify which user to update.

3. **Incorrect Data Structure**: The webhook was storing raw Stripe subscription data instead of the simplified structure expected by the app.

4. **Missing Database Fields**: The `user_subscriptions` table was missing `stripe_subscription_id` and `stripe_price_id` fields needed for webhook processing.

## Fixes Applied

### 1. Updated Checkout Session Creation

- Added user's Supabase ID to checkout session metadata
- File: `supabase/functions/create-checkout-session/index.ts`

### 2. Fixed Stripe Webhook Handler

- Changed from `subscriptions` table to `user_subscriptions` table
- Updated data structure to match app expectations
- Added proper handling for subscription updates and cancellations
- File: `supabase/functions/stripe-webhook/index.ts`

### 3. Updated Database Schema

- Added `stripe_subscription_id` and `stripe_price_id` fields to `user_subscriptions` table
- Added database index for faster webhook lookups
- Files: `supabase_setup.sql`, `supabase/migrations/add_stripe_fields.sql`

### 4. Added App Lifecycle Handling

- App now refreshes subscription status when resumed (after returning from Stripe)
- File: `lib/main.dart`

## Payment Flow (After Fix)

1. User clicks "Upgrade to Traveler Pass"
2. App calls `create-checkout-session` function with price ID
3. Function creates Stripe checkout session with user's Supabase ID in metadata
4. User is redirected to Stripe checkout page
5. User completes payment
6. Stripe sends webhook to `stripe-webhook` function
7. Webhook updates `user_subscriptions` table with:
   - `subscription_type: 'traveler_pass'`
   - `status: 'active'`
   - `plan_duration: 'monthly'` or `'yearly'`
   - Stripe subscription details
8. User is redirected back to app
9. App refreshes subscription status on resume
10. User now has unlimited scans (Traveler Pass active)

## Testing the Fix

To test that the payment flow works:

1. Ensure the Stripe webhook endpoint is configured in your Stripe dashboard
2. Use Stripe test mode with test card numbers
3. Complete a test payment
4. Verify the `user_subscriptions` table is updated correctly
5. Verify the app shows "Traveler Pass" instead of "Free Plan"

## Database Migration

If you have an existing database, run the migration:

```sql
-- Add Stripe-specific fields to user_subscriptions table
ALTER TABLE public.user_subscriptions
ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_price_id TEXT;

-- Create index for faster lookups by Stripe subscription ID
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_stripe_subscription_id
ON public.user_subscriptions(stripe_subscription_id);
```
