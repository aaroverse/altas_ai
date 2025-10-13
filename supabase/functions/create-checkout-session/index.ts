import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@11.1.0?target=deno";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY");
const SUCCESS_URL = Deno.env.get("SITE_URL");
const CANCEL_URL = Deno.env.get("SITE_URL");

console.log("Environment check:", {
  hasStripeKey: !!STRIPE_SECRET_KEY,
  siteUrl: SUCCESS_URL,
  supabaseUrl: Deno.env.get("SUPABASE_URL"),
});

if (!STRIPE_SECRET_KEY) {
  console.error("STRIPE_SECRET_KEY is not set");
}

const stripe = new Stripe(STRIPE_SECRET_KEY!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("Request received:", req.method, req.url);

    const { priceId } = await req.json();
    console.log("Price ID received:", priceId);

    if (!priceId) {
      return new Response(JSON.stringify({ error: "priceId is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

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

    // Create Supabase client with service role to verify JWT
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Verify the JWT and get user
    const jwt = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: userError,
    } = await supabaseAdmin.auth.getUser(jwt);

    console.log("User check:", {
      hasUser: !!user,
      userId: user?.id,
      userError: userError?.message,
    });

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

    let { data: customer, error } = await supabaseAdmin
      .from("customers")
      .select("stripe_customer_id")
      .eq("id", user.id)
      .single();

    console.log("Customer lookup:", { hasCustomer: !!customer, error });

    if (error || !customer) {
      console.log("Creating new Stripe customer for user:", user.id);
      const stripeCustomer = await stripe.customers.create({
        email: user.email,
        metadata: { supabase_id: user.id },
      });

      const { error: insertError } = await supabaseAdmin
        .from("customers")
        .insert({ id: user.id, stripe_customer_id: stripeCustomer.id });

      if (insertError) {
        console.error("Error inserting customer:", insertError);
      }

      customer = { stripe_customer_id: stripeCustomer.id };
    }

    console.log(
      "Creating checkout session for customer:",
      customer.stripe_customer_id
    );

    const session = await stripe.checkout.sessions.create({
      customer: customer.stripe_customer_id,
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${SUCCESS_URL}?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: CANCEL_URL,
      metadata: {
        supabase_id: user.id,
      },
    });

    console.log("Checkout session created:", session.id);

    return new Response(
      JSON.stringify({ sessionId: session.id, url: session.url }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (e) {
    console.error("Error in create-checkout-session:", e);
    return new Response(JSON.stringify({ error: e.message, stack: e.stack }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
