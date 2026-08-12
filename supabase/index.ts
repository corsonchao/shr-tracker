// Supabase Edge Function: claude-suggest
// Proxies task-suggestion requests to the Anthropic API so the API key
// never appears in the public GitHub repo or the browser.
//
// Deploy:   supabase functions deploy claude-suggest --no-verify-jwt
// Secret:   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//
// The model below can be swapped for "claude-haiku-4-5" to cut cost ~3x,
// or a more capable model for richer planning. Check current model names at
// https://docs.claude.com/en/docs/about-claude/models/overview

const CORS = {
  "Access-Control-Allow-Origin": "*", // optionally restrict to your GitHub Pages origin
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const { milestone, workstreamName, memberName, existingTasks, knowledge, weekOf } =
      await req.json();

    const system =
      "You are the planning assistant for the Bezos Earth Fund Superhot Rock team. " +
      "You break upcoming milestones into concrete weekly tasks, grounded in the team's " +
      "knowledge base and consistent with tasks already tracked in other workstreams. " +
      "Respond ONLY with a JSON array, no prose, no markdown fences. Each element: " +
      '{"title": string, "priority": "high"|"medium"|"low", "deadline": "YYYY-MM-DD", "rationale": string}. ' +
      "3-7 tasks. Deadlines must be realistic relative to the milestone and the week given.";

    const user = [
      `Week of: ${weekOf}`,
      `Workstream: ${workstreamName}`,
      `Team member: ${memberName}`,
      `Upcoming milestone: ${milestone}`,
      "",
      "=== Relevant knowledge base excerpts (SHR bible) ===",
      knowledge || "(none provided)",
      "",
      "=== Existing tasks across workstreams (avoid duplicates; learn from patterns) ===",
      existingTasks || "(none)",
    ].join("\n");

    const resp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": Deno.env.get("ANTHROPIC_API_KEY") ?? "",
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 1200,
        system,
        messages: [{ role: "user", content: user }],
      }),
    });

    const data = await resp.json();
    if (!resp.ok) {
      return new Response(JSON.stringify({ error: data?.error?.message || "API error" }), {
        status: 500,
        headers: { ...CORS, "content-type": "application/json" },
      });
    }

    const text = (data.content || [])
      .filter((b: { type: string }) => b.type === "text")
      .map((b: { text: string }) => b.text)
      .join("\n")
      .replace(/```json|```/g, "")
      .trim();

    let suggestions;
    try {
      suggestions = JSON.parse(text);
    } catch {
      return new Response(JSON.stringify({ error: "Model returned unparseable output", raw: text }), {
        status: 502,
        headers: { ...CORS, "content-type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ suggestions, usage: data.usage }), {
      headers: { ...CORS, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 400,
      headers: { ...CORS, "content-type": "application/json" },
    });
  }
});
