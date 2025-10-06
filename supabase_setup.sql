-- Supabase Setup for MenuSense App
-- Run these SQL commands in your Supabase SQL Editor

-- 1. Create profiles table to store user profile information
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create user_subscriptions table to track subscription status
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    subscription_type TEXT NOT NULL DEFAULT 'free', -- 'free', 'traveler_pass'
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'inactive', 'cancelled', 'expired'
    plan_duration TEXT, -- 'monthly', 'yearly' (null for free)
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    platform TEXT, -- 'ios', 'android', 'web'
    transaction_id TEXT, -- Store platform-specific transaction ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id) -- One subscription per user
);

-- 3. Create daily_usage table to track daily scan limits
CREATE TABLE IF NOT EXISTS public.daily_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
    scans_used INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, usage_date) -- One record per user per day
);

-- 4. Create usage_tracking table to track app usage (optional)
CREATE TABLE IF NOT EXISTS public.usage_tracking (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    action_type TEXT NOT NULL, -- 'scan', 'translation', 'recommendation'
    metadata JSONB, -- Store additional data about the action
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_tracking ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for profiles table
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 6. Create RLS policies for user_subscriptions table
CREATE POLICY "Users can view own subscription" ON public.user_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription" ON public.user_subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription" ON public.user_subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 7. Create RLS policies for daily_usage table
CREATE POLICY "Users can view own daily usage" ON public.daily_usage
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own daily usage" ON public.daily_usage
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily usage" ON public.daily_usage
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 8. Create RLS policies for usage_tracking table
CREATE POLICY "Users can view own usage" ON public.usage_tracking
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own usage" ON public.usage_tracking
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 8. Create function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    
    -- Create default subscription record (free plan)
    INSERT INTO public.user_subscriptions (user_id, subscription_type, status)
    VALUES (NEW.id, 'free', 'active');
    
    -- Create initial daily usage record
    INSERT INTO public.daily_usage (user_id, usage_date, scans_used)
    VALUES (NEW.id, CURRENT_DATE, 0);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create trigger to call the function on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 10. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. Create triggers for updated_at
CREATE TRIGGER handle_updated_at_profiles
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at_subscriptions
    BEFORE UPDATE ON public.user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at_daily_usage
    BEFORE UPDATE ON public.daily_usage
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 12. Create storage bucket for avatars (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 13. Create storage policy for avatars
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can update their own avatar" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own avatar" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- 14. Create function to increment daily usage
CREATE OR REPLACE FUNCTION public.increment_daily_usage(
    user_id_param UUID,
    usage_date_param DATE
)
RETURNS VOID AS $$
BEGIN
    UPDATE public.daily_usage 
    SET scans_used = scans_used + 1,
        updated_at = NOW()
    WHERE user_id = user_id_param 
    AND usage_date = usage_date_param;
    
    -- If no row was updated, insert a new one
    IF NOT FOUND THEN
        INSERT INTO public.daily_usage (user_id, usage_date, scans_used)
        VALUES (user_id_param, usage_date_param, 1);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;