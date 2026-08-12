# Superhot Rock — Team Tracker

A lightweight, Asana-style task tracker for the Bezos Earth Fund Superhot Rock
team. Static site (hosts free on GitHub Pages) + Supabase (free tier) for
shared, live, multi-user data + an optional Claude-powered planning sidebar.

## Features

- Simple username/password accounts; each person gets their own homepage
- Homepage: weekly macros, highest-urgency tasks, "@needs your input" queue
  (priority-sorted), notifications, and a globe that lights up from the bottom
  as you finish the week's tasks — spins and reads **Complete** at 100%
- Workstreams → subworkstreams (e.g. Well Construction → MIT Automated Lab)
- Four views per workstream: **Table**, **Timeline**, **Calendar**, and
  **Deadlines** (all deadlines, all members, across the workstream and its
  subworkstreams)
- Filter by person and by status (Done / In progress / Not started / Input
  needed); "Input needed" supports @mentioning the person whose input is
  required, which pings their homepage
- Comments and free-text notes on every task; assignments auto-populate the
  assignee's calendar + homepage and send them a notification
- AI sidebar: describe an upcoming milestone → Claude proposes this week's
  tasks, grounded in your SHR knowledge base and existing tasks across
  workstreams → you confirm each one before it's added
- Live updates: everyone sees changes within a second (Supabase realtime)

## Quick start (2 minutes, demo mode)

Open `index.html` in a browser (or push to GitHub Pages). With no
configuration the app runs in **demo mode**: fully functional, sample data,
stored only in your own browser. Log in as `ana`, `ben`, `cynthia`, or `dev`
with any password.

## Going live for the whole team

GitHub Pages serves only static files — it cannot store shared data. Shared
state lives in a free Supabase project (a hosted Postgres database):

1. **Create the database.** Sign up at https://supabase.com → New project.
   In the SQL Editor, paste and run `supabase/schema.sql`.
2. **Connect the site.** In Supabase → Settings → API, copy the *Project URL*
   and *anon public* key into `config.js`.
3. **Deploy the site.** Push this folder to a GitHub repo → Settings → Pages
   → deploy from the `main` branch root. Your team visits
   `https://<org>.github.io/<repo>/`, creates accounts, and everyone sees the
   same live board.

### Enabling the AI sidebar (optional)

The Anthropic API key must never be committed to a public repo or shipped to
the browser, so the app calls a tiny server-side proxy instead:

1. Install the Supabase CLI (https://supabase.com/docs/guides/cli) and log in.
2. From this folder:
   ```
   supabase functions deploy claude-suggest --no-verify-jwt --project-ref <ref>
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-... --project-ref <ref>
   ```
3. Put the function URL in `config.js`:
   `https://<ref>.supabase.co/functions/v1/claude-suggest`

Get an API key at https://console.anthropic.com (note: this is pay-as-you-go
billing, separate from a Claude.ai chat subscription).

## The knowledge base ("SHR bible")

Suggestions are grounded in the `knowledge` table. Add entries either in-app
(AI panel → "Knowledge base" → Add entry) or in bulk via SQL — see
`knowledge/shr-bible-sample.md` for the chunking/tagging format. The app
matches entry tags/titles against the selected workstream and milestone text
and sends the top matches to Claude, along with a digest of existing tasks
across all workstreams (so suggestions learn from what other subworkstreams
are already doing). Nothing is "trained"; updating a knowledge row updates
the very next suggestion.

## Security notes — read before storing anything sensitive

This is convenience-grade security suitable for an internal coordination tool:

- Passwords are SHA-256 hashed in the browser, but the Supabase anon key in
  `config.js` is public by design, and the row-level-security policy is open —
  anyone who finds your Supabase URL + anon key could read/write the board.
  Mitigations if needed: restrict RLS policies, switch to Supabase Auth
  (email/password with real sessions), or keep the repo private and serve via
  Vercel/Netlify with access control.
- Don't store confidential documents in the knowledge base; treat it like a
  shared whiteboard.
- In the edge function, you can restrict `Access-Control-Allow-Origin` to
  your GitHub Pages URL.

## Cost

- GitHub Pages: free. Supabase free tier: 500 MB database, plenty for years
  of tasks (verify current limits at https://supabase.com/pricing).
- Claude API: each suggestion call sends roughly 3–8k input tokens (knowledge
  excerpts + task digest) and returns ~300–800 output tokens. See the chat
  answer accompanying this repo, or Anthropic's pricing page via
  https://docs.claude.com, for current per-token rates. To cut cost ~3x,
  change the model in `supabase/functions/claude-suggest/index.ts` to
  `claude-haiku-4-5`.

## File map

```
index.html                              the whole app (vanilla JS, no build step)
config.js                               the only file you edit to go live
supabase/schema.sql                     database tables + realtime + seed
supabase/functions/claude-suggest/      Claude API proxy (keeps key secret)
knowledge/shr-bible-sample.md           how to structure your SHR bible
```
