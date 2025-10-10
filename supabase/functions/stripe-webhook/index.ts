import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  SUPABASE_SERVICE_ROLE_KEY ?? ''
)

serve(async (req) => {
  const signature = req.headers.get('Stripe-Signature')
  const body = await req.text()
  let event

  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      STRIPE_WEBHOOK_SECRET
    )
  } catch (err) {
    return new Response(err.message, { status: 400 })
  }

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object
        // Note: Make sure to add the user's Supabase ID to the checkout session metadata
        const userId = session.metadata?.supabase_id
        if (!userId) {
          throw new Error('User ID not found in checkout session metadata.')
        }

        const subscription = await stripe.subscriptions.retrieve(session.subscription)
        
        await supabaseAdmin
          .from('subscriptions')
          .insert({
            id: subscription.id,
            user_id: userId,
            status: subscription.status,
            price_id: subscription.items.data[0].price.id,
            cancel_at_period_end: subscription.cancel_at_period_end,
            current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
            ended_at: subscription.ended_at ? new Date(subscription.ended_at * 1000).toISOString() : null,
            cancel_at: subscription.cancel_at ? new Date(subscription.cancel_at * 1000).toISOString() : null,
            canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
            trial_start: subscription.trial_start ? new Date(subscription.trial_start * 1000).toISOString() : null,
            trial_end: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
          })
        break
      }
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted': {
        const subscription = event.data.object
        await supabaseAdmin
          .from('subscriptions')
          .update({
            status: subscription.status,
            price_id: subscription.items.data[0].price.id,
            cancel_at_period_end: subscription.cancel_at_period_end,
            current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
            ended_at: subscription.ended_at ? new Date(subscription.ended_at * 1000).toISOString() : null,
            cancel_at: subscription.cancel_at ? new Date(subscription.cancel_at * 1000).toISOString() : null,
            canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
            trial_start: subscription.trial_start ? new Date(subscription.trial_start * 1000).toISOString() : null,
            trial_end: subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null,
          })
          .eq('id', subscription.id)
        break
      }
      default:
        // console.log(`Unhandled event type ${event.type}`)
    }
    return new Response(JSON.stringify({ received: true }), { status: 200 })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})