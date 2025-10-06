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

  // Webhook Configuration
  static const String webhookUrl = String.fromEnvironment(
    'WEBHOOK_URL',
    defaultValue:
        'http://srv858154.hstgr.cloud:5678/webhook/afb1492e-cda4-44d5-9906-f91d7525d003',
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
