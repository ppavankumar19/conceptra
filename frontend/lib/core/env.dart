class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lvgsombxkoedcgznqnge.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2Z3NvbWJ4a29lZGNnem5xbmdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NjYwNTMsImV4cCI6MjA4OTQ0MjA1M30.-0wHmCumY47Qlw9W5b8RnMFAAp3l2qfeIShx2aowxKE',
  );
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
