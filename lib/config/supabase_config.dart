/// Optional public client configuration supplied by the app builder.
///
/// Publishable keys are designed to ship in client applications. Database
/// authorization is enforced by Supabase Auth plus Row Level Security; never
/// add a Secret Key or service_role key here.
abstract final class SupabaseConfig {
  static const projectUrl = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
}
