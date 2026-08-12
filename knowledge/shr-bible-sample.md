# SHR Knowledge Base — format guide

The AI sidebar grounds its task suggestions in "knowledge" rows stored in
Supabase (table: `knowledge`). Each row has a **title**, comma-separated
**tags**, and **content**. The app matches tags/titles against the selected
workstream and milestone text, and sends the best-matching chunks to Claude.

Two ways to load your SHR bible:

1. **In-app** — any logged-in member can paste chunks under
   AI Assistant -> "Knowledge base" -> Add entry.
2. **Bulk SQL** — convert sections of the bible into inserts:

```sql
insert into knowledge (title, tags, content) values
('Casing design overview', 'well construction, casing, materials',
 'Paste the relevant section of the SHR bible here...');
```

## Chunking guidance

- One row per coherent topic (roughly 200–800 words). Smaller, well-tagged
  chunks match better than one giant document.
- Tags should reuse your workstream/subworkstream names ("well construction",
  "sensors", "MIT automated lab") plus topical terms ("proppants", "casing",
  "supercritical", "drill bit", "fiber optics").
- Include milestone-relevant facts: typical durations, dependencies,
  lab lead times, procurement steps, review gates, partner names.

## Example entries (placeholders — replace with your real bible content)

---
**Title:** Weekly cadence for lab subworkstreams
**Tags:** process, milestones, planning
**Content:** Lab subworkstreams typically run on a weekly cycle: Monday
planning, mid-week experiment runs, Friday data review. Procurement of
consumables has a 2-week lead time; equipment repairs 3–6 weeks. Tasks that
depend on external partners should be created at least two weeks before the
milestone they support.

---
**Title:** Milestone review checklist
**Tags:** process, review, reporting
**Content:** Before any milestone review: 1) results summary drafted,
2) risks and blockers listed with owners, 3) next-quarter asks quantified,
4) slides circulated 48h in advance for comments.
