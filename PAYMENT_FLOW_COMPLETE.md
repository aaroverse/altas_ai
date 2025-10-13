# Payment Flow - Complete Setup

## ✅ All Issues Fixed

1. ✅ Database schema updated with Stripe fields
2. ✅ Webhook configured to accept Stripe requests (no JWT required)
3. ✅ User lookup works via metadata or customer ID
4. ✅ Checkout session includes user metadata
5. ✅ Library versions reverted to working versions

## What Was Fixed

### 1. Database Migration

- Added `stripe_subscription_id` and `stripe_price_id` fields to `user_subscriptions` table
- Removed old `subscriptions` table if it existed
- Added index for faster webhook lookups

### 2. Webhook Authentication

- Changed `verify_jwt = false` in `supabase/config.toml` for stripe-webhook function
- Webhook now accepts Stripe requests without requiring Authorization header
- Uses Stripe signature verification for security instead

### 3. User Identification

- Checkout session now includes user's Supabase ID in metadata
- Webhook has fallback to look up user by Stripe customer ID
- Uses service role key to bypass RLS policies

### 4. Library Versions

- Reverted to stable versions that were working before:
  - `std@0.168.0`
  - `@supabase/supabase-js@2`
  - `stripe@11.1.0`
  - API version: `2023-10-16`

## Next Steps

### 1. Configure Stripe Webhook (Required!)

Go to Stripe Dashboard and set up the webhook:

- **URL**: `https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/stripe-webhook`
- **Events**:
  - `checkout.session.completed`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`

### 2. Set Webhook Secret

After creating the webhook in Stripe:

```bash
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_your_secret_from_stripe
```

### 3. Test the Flow

1. Click "Get Traveler Pass" in your app
2. Complete payment with test card: `4242 4242 4242 4242`
3. Check Stripe webhook logs - should show 200 OK
4. Check `user_subscriptions` table - should show `traveler_pass` with `active` status
5. Return to app - should show unlimited scans

## Testing Checklist

- [ ] Stripe webhook endpoint configured with correct URL
- [ ] Webhook events selected (checkout.session.completed, etc.)
- [ ] Webhook secret set in Supabase
- [ ] Test payment completes successfully
- [ ] Webhook returns 200 OK in Stripe logs
- [ ] User subscription updated in database
- [ ] App shows "Traveler Pass" instead of "Free Plan"
- [ ] User has unlimited scans

## Files Modified

### Edge Functions

- `supabase/functions/create-checkout-session/index.ts` - Fixed authentication, added metadata
- `supabase/functions/stripe-webhook/index.ts` - Fixed user lookup, updated table name

### Configuration

- `supabase/config.toml` - Set `verify_jwt = false` for webhook

### Database

- `supabase_setup.sql` - Added Stripe fields to schema
- `supabase/migrations/20251010165315_add_stripe_fields.sql` - Migration for existing databases
- `supabase/migrations/20251010170000_cleanup_old_tables.sql` - Cleanup old tables

### App

- `lib/main.dart` - Simplified authentication handling

## Verification

To verify everything is working:

1. **Check webhook is accessible**:

   ```bash
   curl -X POST https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/stripe-webhook \
     -H "Stripe-Signature: test" \
     -d '{}'
   ```

   Should return: "Webhook signature verification failed" (this is good!)

2. **Check secrets are set**:

   ```bash
   supabase secrets list
   ```

   Should show: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, SUPABASE_SERVICE_ROLE_KEY

3. **Check database schema**:
   ```sql
   SELECT column_name FROM information_schema.columns
   WHERE table_name = 'user_subscriptions';
   ```
   Should include: stripe_subscription_id, stripe_price_id

## Support

If you encounter issues:

1. Check Stripe webhook logs for delivery status
2. Check Supabase function logs for errors
3. Verify all secrets are set correctly
4. Ensure webhook events are selected in Stripe
5. Test with Stripe test mode first before going live
