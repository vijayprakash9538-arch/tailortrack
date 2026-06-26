/// Supabase connection settings.
///
/// The URL and the **publishable** key are safe to ship in the client — they
/// are public by design and every row is protected by Row Level Security.
/// The *secret* (service-role) key is NEVER referenced in the app.
///
/// Values can be overridden at build time without touching source:
///   flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bigayvovjlenosacjnoa.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_KnrvFpsuX1Tmf7rnlKv9bw_WHq4k1J4',
  );
}
