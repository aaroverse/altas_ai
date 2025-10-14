# Deploy Edge Function Fix

## What Was Fixed

Updated `create-checkout-session` Edge Function to:

1. **Verify customer exists in Stripe** before using the ID
2. **Create new customer** if verification fails
3. **Update Stripe library** to latest version
4. **Use upsert** instead of insert to avoid conflicts

This fixes the error: `No such customer: 'cus_TD1Xj51GD2W2T6'`

## How to Deploy

### Option 1: Using Supabase CLI (Recommended)

1. **Install Supabase CLI** (if not already installed):

   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:

   ```bash
   supabase login
   ```

3. **Link to your project**:

   ```bash
   supabase link --project-ref gkpanxesanutgpwhsuzr
   ```

4. **Deploy the function**:
   ```bash
   supabase functions deploy create-checkout-session
   ```

### Option 2: Using Supabase Dashboard

1. Go to your Supabase Dashboard
2. Navigate to **Edge Functions**
3. Find `create-checkout-session`
4. Click **Edit**
5. Copy the entire content from `supabase/functions/create-checkout-session/index.ts`
6. Paste it into the editor
7. Click **Deploy**

### Option 3: Manual Copy-Paste

If you can't use the CLI, you can manually update the function in the Supabase dashboard:

1. Open `supabase/functions/create-checkout-session/index.ts` in your editor
2. Copy all the code
3. Go to Supabase Dashboard → Edge Functions → create-checkout-session
4. Paste the code
5. Deploy

## Verify Deployment

After deploying, test the upgrade flow:

1. Go to your app
2. Try to upgrade to Traveler Pass
3. The function should now:
   - Check if customer exists in Stripe
   - Create new customer if needed
   - Redirect to Stripe checkout successfully

## Environment Variables

Make sure these are set in Supabase Edge Functions:

- `STRIPE_SECRET_KEY` - Your Stripe secret key (test or live)
- `SUPABASE_URL` - Your Supabase URL
- `SUPABASE_SERVICE_ROLE_KEY` - Your Supabase service role key
- `SITE_URL` - Your website URL (for redirects)

## Troubleshooting

### Still getting customer error?

1. **Check Stripe mode**: Make sure you're using the right keys (test vs live)
2. **Clear customer IDs**: Run this SQL in Supabase:
   ```sql
   UPDATE customers SET stripe_customer_id = NULL;
   ```
3. **Check logs**: View Edge Function logs in Supabase dashboard

### Function not deploying?

1. Make sure you're logged in: `supabase login`
2. Make sure you're linked to the right project
3. Check for syntax errors in the TypeScript file

### Deployment successful but still errors?

1. Wait 1-2 minutes for the function to fully deploy
2. Clear your browser cache
3. Try the upgrade flow again
4. Check Edge Function logs for detailed error messages

## Next Steps

After successful deployment:

1. Test the upgrade flow
2. Verify customer is created in Stripe
3. Check that subscription is created correctly
4. Test the webhook for subscription updates

The error should be completely resolved!
