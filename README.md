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
   Then open the file `supabase/schema.sql`, select **all of its text** and
   copy it, and paste that text into Supabase → SQL Editor → New query → Run.
   (Pasting the file *path* instead of its contents gives
   `syntax error at or near "supabase"` — that's the most common slip.)
   The script is safe to run more than once; it ends by listing the six
   tables it created.
2. **Connect the site.** Fill in `config.js` with two values from the
   Supabase dashboard:
   - **Project URL** — Settings → Data API (or the green **Connect** button
     at the top of the dashboard). Format: `https://<project-ref>.supabase.co`
   - **Publishable key** — Settings → API Keys → *Publishable key*, starting
     `sb_publishable_`. This replaced the old "anon public" key and is meant
     to be public; Row Level Security controls what it can do. Older projects
     can use the legacy `anon public` key (a long `eyJ...` string) under the
     Legacy API Keys tab instead — the app accepts either.

   **Never paste the secret key** (`sb_secret_...`). It bypasses Row Level
   Security, and Supabase automatically revokes secret keys it detects in
   public GitHub repositories. The app refuses to start if it finds one.
3. **Deploy the site.** Push this folder to a GitHub repo → Settings → Pages
   → deploy from the `main` branch root. Your team visits
   `https://<org>.github.io/<repo>/`, creates accounts, and everyone sees the
   same live board.

### Enabling the AI sidebar — pick any one of these

The Anthropic API key must never sit in a public repo or be shipped to every
visitor, so the sidebar either calls a small server-side proxy or uses a key
each person stores in their own browser. **No CLI or Docker is required for
any option below.** Get a key first at https://console.anthropic.com
(pay-as-you-go, billed separately from a Claude.ai subscription).

**Option A — personal key, zero deployment (fastest).**
Open the app → ✦ AI assistant → paste your `sk-ant-…` key → Connect Claude.
The key is saved in that browser only (localStorage): never committed, never
sent to teammates, never visible in the repo. Each person who wants
suggestions adds their own key once. Best for trying it out, or for a team
where two or three people use the feature.

**Option B — Supabase Edge Function via the dashboard (no CLI, no Docker).**
Supabase can deploy functions straight from the browser:
1. Dashboard → **Edge Functions** → **Deploy a new function** → **Via Editor**
2. Name it `claude-suggest`, delete the sample code, and paste the contents of
   `supabase/functions/claude-suggest/index.ts`
3. In the function's settings, turn **Verify JWT** off (or leave it on — the
   app sends your publishable key on the Authorization header either way)
4. **Deploy**
5. Edge Functions → **Secrets** → add `ANTHROPIC_API_KEY` = your `sk-ant-…`
6. Put the function URL in `config.js` → `AI_ENDPOINT`:
   `https://<project-ref>.supabase.co/functions/v1/claude-suggest`
Note: the dashboard editor has no version history, so keep the file in this
repo as the source of truth.

**Option C — Cloudflare Worker (no CLI, no Docker, no Supabase).**
Paste `alt-hosts/cloudflare-worker.js` into Cloudflare's browser editor, add
`ANTHROPIC_API_KEY` as a secret, and use the Worker URL as `AI_ENDPOINT`.
Step-by-step instructions are in the comments at the top of that file.

**Option D — CLI without Docker,** if you'd still rather use it:
`npx supabase functions deploy claude-suggest --use-api --project-ref <ref>`.
The `--use-api` flag skips Docker entirely, and `npx` avoids Scoop and the
global install.

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
supabase/functions/claude-suggest/      Claude API proxy (Supabase Edge Function)
alt-hosts/cloudflare-worker.js          same proxy, for Cloudflare Workers
knowledge/shr-bible-sample.md           how to structure your SHR bible
```
