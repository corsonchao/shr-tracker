// ── Superhot Rock Tracker configuration ──────────────────────────────
// Leave SUPABASE_URL empty ("") to run in DEMO MODE: the app works fully
// in your browser with sample data (nothing is shared between people).
//
// To go live (shared, multi-user):
//   1. Create a free project at https://supabase.com
//   2. Run supabase/schema.sql in the SQL editor
//   3. Paste your Project URL and anon public key below
//   4. Deploy supabase/functions/claude-suggest and paste its URL below
//      to enable the AI task-suggestion sidebar (optional).

window.SHR_CONFIG = {
  SUPABASE_URL: "",        // e.g. "https://abcdefgh.supabase.co"
  SUPABASE_ANON_KEY: "",   // Settings -> API -> anon public
  AI_ENDPOINT: "",         // e.g. "https://abcdefgh.supabase.co/functions/v1/claude-suggest"
};
