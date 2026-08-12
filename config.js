// ── Superhot Rock Tracker configuration ──────────────────────────────
// Leave SUPABASE_URL empty ("") to run in DEMO MODE: the app works fully
// in your browser with sample data (nothing is shared between people).
//
// To go live (shared, multi-user):
//   1. Create a free project at https://supabase.com
//   2. Run supabase/schema.sql in the SQL editor (copy the file's CONTENTS)
//   3. Fill in the two values below — Dashboard -> Settings -> API Keys
//   4. Optional: deploy supabase/functions/claude-suggest and paste its URL
//      into AI_ENDPOINT to enable the AI task-suggestion sidebar.

window.SHR_CONFIG = {
  // Project URL — Settings -> Data API (or the green "Connect" button).
  // Looks like: https://abcdefghijklmnop.supabase.co
  SUPABASE_URL: "https://aiwelyvzsbxkpnefrcdj.supabase.co/rest/v1/",

  // PUBLISHABLE key — Settings -> API Keys -> "Publishable key".
  // Starts with sb_publishable_...  This one is designed to be public and
  // is safe in a GitHub repo; Row Level Security governs what it can do.
  //
  // NEVER put the SECRET key (sb_secret_...) here. It bypasses Row Level
  // Security, and Supabase auto-revokes secret keys it detects in public
  // GitHub repositories.
  //
  // Older projects: use the legacy "anon public" key (a long eyJ... string)
  // from the Legacy API Keys tab — it works identically here.
  SUPABASE_PUBLISHABLE_KEY: "sb_publishable_wQXuka3asJH-OOk1l7bJqg_VqgBpZ_l",

  AI_ENDPOINT: "", // e.g. "https://abcdefgh.supabase.co/functions/v1/claude-suggest"
};
