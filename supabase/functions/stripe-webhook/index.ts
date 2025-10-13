import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@11.1.0?target=deno";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = Deno.env.get("STRIPE_WEBHOOK_SECRET");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

console.log("Environment check:", {
  hasStripeKey: !!STRIPE_SECRET_KEY,
  hasWebhookSecret: !!STRIPE_WEBHOOK_SECRET,
  hasSupabaseKey: !!SUPABASE_SERVICE_ROLE_KEY,
});

const stripe = new Stripe(STRIPE_SECRET_KEY!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

// Create admin client for webhook operations (bypasses RLS)
const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  SUPABASE_SERVICE_ROLE_KEY ?? ""
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, stripe-signature",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  console.log("Webhook received:", req.method, req.url);

  // For webhooks, we don't need user authentication, just environment validation
  if (
    !STRIPE_SECRET_KEY ||
    !STRIPE_WEBHOOK_SECRET ||
    !SUPABASE_SERVICE_ROLE_KEY
  ) {
    console.error("Missing required environment variables");
    return new Response("Server configuration error", {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const signature = req.headers.get("Stripe-Signature");
  const body = await req.text();

  console.log("Request details:", {
    hasSignature: !!signature,
    bodyLength: body.length,
    hasWebhookSecret: !!STRIPE_WEBHOOK_SECRET,
  });

  if (!STRIPE_WEBHOOK_SECRET) {
    console.error("STRIPE_WEBHOOK_SECRET is not set");
    return new Response("Webhook secret not configured", {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!signature) {
    console.error("No Stripe signature found");
    return new Response("No signature found", {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let event;

  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      STRIPE_WEBHOOK_SECRET
    );
    console.log("Webhook event verified:", event.type);
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return new Response(
      `Webhook signature verification failed: ${err.message}`,
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        console.log("Processing checkout.session.completed:", {
          sessionId: session.id,
          customerId: session.customer,
          metadata: session.metadata,
        });

        // Try to get user ID from metadata first
        let userId = session.metadata?.supabase_id;

        // If not in metadata, try to find user by customer ID
        if (!userId && session.customer) {
          console.log(
            "No user ID in metadata, looking up by customer ID:",
            session.customer
          );
          const { data: customerData, error: customerError } =
            await supabaseAdmin
              .from("customers")
              .select("id")
              .eq("stripe_customer_id", session.customer)
              .single();

          if (customerData && !customerError) {
            userId = customerData.id;
            console.log("Found user ID from customer lookup:", userId);
          } else {
            console.error("Customer lookup failed:", customerError);
          }
        }

        if (!userId) {
          console.error("User ID not found in metadata or customer lookup", {
            metadata: session.metadata,
            customerId: session.customer,
          });
          throw new Error(
            "User ID not found in checkout session metadata or customer lookup."
          );
        }

        const subscription = await stripe.subscriptions.retrieve(
          session.subscription
        );
        const priceId = subscription.items.data[0].price.id;

        // Determine plan duration based on price ID or interval
        const interval = subscription.items.data[0].price.recurring?.interval;
        const planDuration = interval === "year" ? "yearly" : "monthly";

        // Calculate end date
        const endDate = new Date(subscription.current_period_end * 1000);

        // Update user_subscriptions table with Traveler Pass
        await supabaseAdmin.from("user_subscriptions").upsert(
          {
            user_id: userId,
            subscription_type: "traveler_pass",
            status: "active",
            plan_duration: planDuration,
            start_date: new Date(
              subscription.current_period_start * 1000
            ).toISOString(),
            end_date: endDate.toISOString(),
            platform: "stripe",
            transaction_id: subscription.id,
            stripe_subscription_id: subscription.id,
            stripe_price_id: priceId,
          },
          {
            onConflict: "user_id",
          }
        );

        console.log(`Successfully activated Traveler Pass for user ${userId}`);
        break;
      }
      case "customer.subscription.updated": {
        const subscription = event.data.object;
        const priceId = subscription.items.data[0].price.id;
        const interval = subscription.items.data[0].price.recurring?.interval;
        const planDuration = interval === "year" ? "yearly" : "monthly";
        const endDate = new Date(subscription.current_period_end * 1000);

        // Determine status based on Stripe subscription status
        let status = "active";
        if (
          subscription.status === "canceled" ||
          subscription.status === "incomplete_expired"
        ) {
          status = "inactive";
        } else if (subscription.status === "past_due") {
          status = "past_due";
        } else if (subscription.cancel_at_period_end) {
          // Subscription is set to cancel at period end
          status = "cancelling";
        }

        await supabaseAdmin
          .from("user_subscriptions")
          .update({
            status: status,
            plan_duration: planDuration,
            end_date: endDate.toISOString(),
            stripe_subscription_id: subscription.id,
            stripe_price_id: priceId,
          })
          .eq("stripe_subscription_id", subscription.id);

        console.log(
          `Updated subscription ${subscription.id} with status ${status}`
        );
        break;
      }
      case "customer.subscription.deleted": {
        const subscription = event.data.object;

        await supabaseAdmin
          .from("user_subscriptions")
          .update({
            status: "inactive",
            end_date: new Date().toISOString(),
          })
          .eq("stripe_subscription_id", subscription.id);

        console.log(`Deactivated subscription ${subscription.id}`);
        break;
      }
      default:
      // console.log(`Unhandled event type ${event.type}`)
    }
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error processing webhook:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
