-- Add Stripe-specific fields to user_subscriptions table
ALTER TABLE public.user_subscriptions 
ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_price_id TEXT;

-- Create index for faster lookups by Stripe subscription ID
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_stripe_subscription_id 
ON public.user_subscriptions(stripe_subscription_id);