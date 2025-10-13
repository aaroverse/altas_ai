-- Create app_config table for backend configuration
CREATE TABLE IF NOT EXISTS app_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default free plan daily limit
INSERT INTO app_config (key, value, description)
VALUES 
  ('free_daily_scan_limit', '3', 'Number of free scans allowed per day for non-subscribed users')
ON CONFLICT (key) DO NOTHING;

-- Create function to update timestamp
CREATE OR REPLACE FUNCTION update_app_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS update_app_config_timestamp_trigger ON app_config;
CREATE TRIGGER update_app_config_timestamp_trigger
  BEFORE UPDATE ON app_config
  FOR EACH ROW
  EXECUTE FUNCTION update_app_config_timestamp();

-- Enable RLS
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read config
CREATE POLICY "Allow authenticated users to read app config"
  ON app_config
  FOR SELECT
  TO authenticated
  USING (true);

-- Only service role can update config (via Supabase dashboard or admin functions)
CREATE POLICY "Only service role can update app config"
  ON app_config
  FOR ALL
  TO service_role
  USING (true);
