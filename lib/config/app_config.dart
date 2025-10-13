class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue:
        'https://your-project.supabase.co', // Fallback for development
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here', // Fallback for development
  );

  // Webhook Configuration - Using Supabase Edge Function as HTTPS proxy
  static const String webhookUrl = String.fromEnvironment(
    'WEBHOOK_URL',
    defaultValue:
        'https://gkpanxesanutgpwhsuzr.supabase.co/functions/v1/process-menu',
  );

  // App Configuration
  static const String appName = 'Altas AI';
  static const String appVersion = '1.0.0';

  // Development vs Production
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  // Validate configuration
  static bool get isConfigValid {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('your-project') &&
        !supabaseAnonKey.contains('your-anon-key');
  }
}
