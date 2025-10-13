import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@11.1.0?target=deno";

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const stripe = new Stripe(STRIPE_SECRET_KEY!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const supabaseAdmin = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  SUPABASE_SERVICE_ROLE_KEY ?? ""
);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("Resume subscription request received");

    // Get JWT token from Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify the JWT and get user
    const jwt = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: userError,
    } = await supabaseAdmin.auth.getUser(jwt);

    if (!user) {
      console.error("No user found. Auth error:", userError);
      return new Response(
        JSON.stringify({
          error: "Unauthorized",
          details: userError?.message || "No authenticated user found",
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { subscriptionId } = await req.json();

    if (!subscriptionId) {
      return new Response(
        JSON.stringify({ error: "subscriptionId is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log("Resuming subscription:", subscriptionId, "for user:", user.id);

    // Verify that the subscription belongs to the user
    const { data: subscription, error: subError } = await supabaseAdmin
      .from("user_subscriptions")
      .select("*")
      .eq("user_id", user.id)
      .eq("stripe_subscription_id", subscriptionId)
      .single();

    if (subError || !subscription) {
      console.error(
        "Subscription not found or doesn't belong to user:",
        subError
      );
      return new Response(JSON.stringify({ error: "Subscription not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check if subscription is in cancelling state
    if (subscription.status !== "cancelling") {
      return new Response(
        JSON.stringify({ error: "Subscription is not in cancelling state" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Resume the subscription in Stripe (remove cancel_at_period_end)
    const resumedSubscription = await stripe.subscriptions.update(
      subscriptionId,
      {
        cancel_at_period_end: false,
      }
    );

    console.log("Subscription resumed in Stripe:", resumedSubscription.id);

    // Update the subscription status in Supabase
    await supabaseAdmin
      .from("user_subscriptions")
      .update({
        status: "active",
        updated_at: new Date().toISOString(),
      })
      .eq("stripe_subscription_id", subscriptionId);

    console.log("Subscription status updated to active in Supabase");

    return new Response(
      JSON.stringify({
        success: true,
        message: "Subscription resumed successfully",
        renewsOn: new Date(
          resumedSubscription.current_period_end * 1000
        ).toISOString(),
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (e) {
    console.error("Error in resume-subscription:", e);
    return new Response(JSON.stringify({ error: e.message, stack: e.stack }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
