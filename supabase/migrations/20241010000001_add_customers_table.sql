-- Create customers table for Stripe integration
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    stripe_customer_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own customer record" ON public.customers
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own customer record" ON public.customers
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own customer record" ON public.customers
    FOR UPDATE USING (auth.uid() = id);

-- Create trigger for updated_at
CREATE TRIGGER handle_updated_at_customers
    BEFORE UPDATE ON public.customers
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();