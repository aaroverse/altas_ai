-- Drop old subscriptions table if it exists (we use user_subscriptions instead)
DROP TABLE IF EXISTS public.subscriptions CASCADE;

-- Ensure user_subscriptions has all required fields
ALTER TABLE public.user_subscriptions 
ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_price_id TEXT;

-- Create index if not exists
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_stripe_subscription_id 
ON public.user_subscriptions(stripe_subscription_id);
