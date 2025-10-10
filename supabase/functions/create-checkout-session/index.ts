import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')
const SUCCESS_URL = Deno.env.get('SITE_URL')
const CANCEL_URL = Deno.env.get('SITE_URL')

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
  try {
    const { priceId } = await req.json()
    if (!priceId) {
      return new Response(JSON.stringify({ error: 'priceId is required' }), { status: 400, headers: { 'Content-Type': 'application/json' } })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json' } })
    }

    let { data: customer, error } = await supabase
      .from('customers')
      .select('stripe_customer_id')
      .eq('id', user.id)
      .single()

    if (error || !customer) {
      const stripeCustomer = await stripe.customers.create({
        email: user.email,
        metadata: { supabase_id: user.id },
      })
      await supabase.from('customers').insert({ id: user.id, stripe_customer_id: stripeCustomer.id })
      customer = { stripe_customer_id: stripeCustomer.id }
    }

    const session = await stripe.checkout.sessions.create({
      customer: customer.stripe_customer_id,
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${SUCCESS_URL}/success`,
      cancel_url: CANCEL_URL,
    })

    return new Response(JSON.stringify({ sessionId: session.id, url: session.url }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
})