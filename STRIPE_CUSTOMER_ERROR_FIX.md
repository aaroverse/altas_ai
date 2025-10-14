# Stripe Customer Error Fix

## Error

```
Error: FunctionException(status: 500, details: {error: No such customer: 'cus_TD1Xj51GD2W2T6'
```

## Root Cause

Your Supabase Edge Function `create-checkout-session` is trying to use a Stripe customer ID that doesn't exist. This happens when:

1. **Test vs Live Mode Mismatch**: Customer was created in test mode but you're using live mode keys (or vice versa)
2. **Customer Deleted**: The customer was deleted from Stripe but the ID is still in your database
3. **Wrong Customer ID**: The customer ID in your database doesn't match Stripe

## Solution

You need to update your `create-checkout-session` Edge Function to handle this properly.

### Option 1: Create Customer If Not Exists (Recommended)

Update your Edge Function to create a new customer if the existing one doesn't exist:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const {
      data: { user },
    } = await supabaseClient.auth.getUser();

    if (!user) {
      throw new Error("Not authenticated");
    }

    const { priceId } = await req.json();

    if (!priceId) {
      throw new Error("Price ID is required");
    }

    // Get or create Stripe customer
    let customerId: string | null = null;

    // Try to get existing customer from profiles table
    const { data: profile } = await supabaseClient
      .from("profiles")
      .select("stripe_customer_id")
      .eq("id", user.id)
      .single();

    if (profile?.stripe_customer_id) {
      // Verify customer exists in Stripe
      try {
        await stripe.customers.retrieve(profile.stripe_customer_id);
        customerId = profile.stripe_customer_id;
      } catch (error) {
        console.log("Customer not found in Stripe, will create new one");
        customerId = null;
      }
    }

    // Create new customer if needed
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: user.email,
        metadata: {
          supabase_user_id: user.id,
        },
      });
      customerId = customer.id;

      // Save customer ID to database
      await supabaseClient.from("profiles").upsert({
        id: user.id,
        stripe_customer_id: customerId,
        updated_at: new Date().toISOString(),
      });
    }

    // Create checkout session
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      mode: "subscription",
      success_url: `${req.headers.get("origin")}/`,
      cancel_url: `${req.headers.get("origin")}/`,
      metadata: {
        user_id: user.id,
      },
    });

    return new Response(JSON.stringify({ url: session.url }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
```

### Option 2: Quick Fix - Clear Customer IDs

If you want a quick fix for testing, clear all customer IDs from your database:

```sql
-- Run this in Supabase SQL Editor
UPDATE profiles SET stripe_customer_id = NULL;
```

Then the Edge Function will create new customers for everyone.

### Option 3: Check Test vs Live Mode

Make sure your Stripe keys match the mode you're using:

1. Go to Supabase Dashboard → **Project Settings** → **Edge Functions** → **Secrets**
2. Check `STRIPE_SECRET_KEY`
3. Test keys start with `sk_test_`
4. Live keys start with `sk_live_`

If you're using test keys, make sure the customer IDs in your database are from test mode.

## Database Schema Update

Make sure your `profiles` table has the `stripe_customer_id` column:

```sql
-- Add column if it doesn't exist
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_stripe_customer_id
ON profiles(stripe_customer_id);
```

## Testing

After updating the Edge Function:

1. Deploy the updated function to Supabase
2. Try upgrading again
3. The function should create a new customer automatically
4. Check Stripe dashboard to verify the customer was created

## Prevention

To prevent this in the future:

1. Always verify customer exists before using the ID
2. Create new customer if verification fails
3. Keep test and live mode data separate
4. Don't delete customers from Stripe if they're referenced in your database

## Immediate Action

1. Update your `create-checkout-session` Edge Function with the code above
2. Deploy it: `supabase functions deploy create-checkout-session`
3. Test the upgrade flow again

The error should be resolved!
