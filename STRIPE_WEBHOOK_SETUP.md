# Stripe Webhook Setup Guide

## ✅ Authentication Issue Fixed

The webhook function has been configured to not require JWT verification, so it now accepts Stripe webhook requests without authentication.

## Setup Instructions

### 1. Configure Stripe Webhook

1. Go to your **Stripe Dashboard** → **Developers** → **Webhooks**
2. Click "Add endpoint" or edit your existing webhook
3. Set the **Endpoint URL** to:

   ```
   https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/stripe-webhook
   ```

4. **Select Events** (important!):

   - ✅ `checkout.session.completed`
   - ✅ `customer.subscription.updated`
   - ✅ `customer.subscription.deleted`

5. **Save the webhook**

### 2. Get and Set the Webhook Signing Secret

After saving the webhook:

1. Click "Reveal" next to "Signing secret" in your webhook settings
2. Copy the secret (starts with `whsec_`)
3. Update your Supabase secret:
   ```bash
   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_your_secret_here
   ```

### 3. Test the Webhook

1. Make a test payment in Stripe (use test mode with card `4242 4242 4242 4242`)
2. Check webhook logs in **Stripe Dashboard** → **Developers** → **Webhooks** → [Your endpoint] → **Recent deliveries**
3. Verify the webhook returns **200 OK**
4. Check your `user_subscriptions` table in Supabase to confirm the subscription was updated

## How It Works

### Payment Flow:

1. User clicks "Get Traveler Pass" → Redirected to Stripe checkout
2. User completes payment → Stripe sends `checkout.session.completed` webhook
3. Webhook function receives event → Looks up user by Stripe customer ID
4. Updates `user_subscriptions` table → Changes from "Free Plan" to "Traveler Pass"
5. User returns to app → Sees unlimited scans

### Database Updates:

The webhook updates the `user_subscriptions` table with:

- `subscription_type`: `'traveler_pass'`
- `status`: `'active'`
- `plan_duration`: `'monthly'` or `'yearly'`
- `stripe_subscription_id`: Stripe subscription ID
- `stripe_price_id`: Stripe price ID
- `start_date` and `end_date`: Subscription period

## Troubleshooting

### Webhook returns 401 Unauthorized

✅ **Fixed**: The function is now configured to accept requests without JWT verification.

### Webhook signature verification failed

- Make sure `STRIPE_WEBHOOK_SECRET` is set correctly in Supabase:
  ```bash
  supabase secrets list
  ```
- The secret should start with `whsec_`
- Get the correct secret from your Stripe webhook endpoint settings

### User subscription not updating after payment

1. **Check Stripe webhook logs**:

   - Go to Stripe Dashboard → Developers → Webhooks → [Your endpoint] → Recent deliveries
   - Look for the `checkout.session.completed` event
   - Check if it returned 200 OK or an error

2. **Check Supabase function logs**:

   - Go to Supabase Dashboard → Edge Functions → stripe-webhook → Logs
   - Look for error messages

3. **Verify customer exists**:

   - Check the `customers` table in Supabase
   - Make sure the user's Stripe customer ID is stored

4. **Check metadata**:
   - The checkout session should include the user's Supabase ID in metadata
   - If not, the webhook will try to look up the user by Stripe customer ID

### Test the webhook manually

You can test if the webhook is accessible:

```bash
curl -X POST https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/stripe-webhook \
  -H "Content-Type: application/json" \
  -H "Stripe-Signature: test" \
  -d '{"test": "data"}'
```

Expected response: "Webhook signature verification failed" (this is normal - it means the endpoint is accessible)

## Configuration Files

The webhook is configured in `supabase/config.toml`:

```toml
[functions.stripe-webhook]
enabled = true
verify_jwt = false  # This allows Stripe webhooks without authentication
```
