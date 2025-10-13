import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const WEBHOOK_URL =
  Deno.env.get("MENU_WEBHOOK_URL") ||
  "http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "Content-Type, Authorization, x-client-info, apikey",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("Processing menu image request...");

    // Get the form data from the request
    const formData = await req.formData();

    // Log the fields for debugging
    const targetLanguage = formData.get("targetLanguage");
    const file = formData.get("file");

    console.log(`Target Language: ${targetLanguage}`);
    console.log(`File received: ${file ? "Yes" : "No"}`);

    if (!file) {
      return new Response(JSON.stringify({ error: "No file provided" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Forward the request to the webhook
    console.log(`Forwarding to webhook: ${WEBHOOK_URL}`);

    const webhookResponse = await fetch(WEBHOOK_URL, {
      method: "POST",
      body: formData,
    });

    console.log(`Webhook response status: ${webhookResponse.status}`);

    if (!webhookResponse.ok) {
      const errorText = await webhookResponse.text();
      console.error(`Webhook error: ${errorText}`);

      return new Response(
        JSON.stringify({
          error: `Webhook returned status ${webhookResponse.status}`,
          details: errorText,
        }),
        {
          status: webhookResponse.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get the response from the webhook
    const responseData = await webhookResponse.json();
    console.log("Webhook response received successfully");

    // Return the response with CORS headers
    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error processing request:", error);

    return new Response(
      JSON.stringify({
        error: "Failed to process menu image",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
