# Reference: Knowledge / Research Harness (worked example)

> **Read this as an example, not a template.** The important idea is "the compiled output *is* the blackboard," not any specific directory layout. Adapt the shape to the project's actual knowledge structure.

---

## When this shape applies

You're building a knowledge base, research wiki, documentation system, or synthesis pipeline from a corpus of source material. The single-agent baseline shows one or more of:

- The agent rewrites old findings instead of building on them; knowledge doesn't compound
- Contradictions between sources go uncaught — the agent takes whatever it read last as truth
- Cross-source synthesis is shallow — each source is summarized in isolation
- The same question gets re-researched because its answer was left in chat history, not filed

If none of these happen, don't build a knowledge harness — the single agent is enough.

---

## Typical roles

- **Coordinator** — routes new sources to the compiler, handles user queries, notices when a query's answer deserves to become a permanent synthesis page.
- **Compiler** — ingests a source, extracts entities, cross-links to existing pages, updates the index, resolves or flags contradictions.
- **QA / Linter** — checks the health of the compiled output: broken links, orphaned pages, missing citations, stale claims, contradictions between pages.

These are role names. For a small project, the coordinator might do all of this. For a large one, the compiler might be multiple specialized agents (one for ingestion, one for synthesis).

---

## The defining structural idea: wiki-is-blackboard

In software harnesses, `.harness/` is separate from the source code. In knowledge harnesses, **there is no separate harness directory — the compiled output is the communication layer**. Pages written by the compiler are read by the linter. The index is the progress metric. The log is the history. Agents collaborate by editing the shared knowledge tree.

```
wiki/ (or kb/, research/, vault/, whatever fits)   ← compiled output; agents own this layer
  index.md                                          ← content directory; doubles as progress metric
  sources/                                          ← one page per raw source, with summary + citations
  concepts/                                         ← cross-source synthesis
  CLAUDE.md                                         ← schema; co-evolves with agents (= spec.md equivalent)
raw/                                                ← immutable input; agents read-only
log.md                                              ← append-only activity timeline (= progress.tsv equivalent)
```

**Source immutability** is especially important here. `raw/` is the ground truth; it never gets modified. Everything in `wiki/` is a derivation. If `wiki/` gets corrupted, you should be able to recompile from `raw/`.

---

## Progress signal: log + index

The coverage metric is usually "how much of raw/ has been compiled, and how healthy is the compiled output?" Concrete ways to make this signal observable:

- **index.md** counts total compiled pages and organizes them hierarchically.
- **log.md** appends one entry per compilation cycle:
  ```
  ## [2026-03-27 10:00] ingest | source-title
  - pages_touched: 7
  - new_pages: 2
  - issues_found: 1 broken link, 0 contradictions
  - coverage: 42/50 sources compiled
  ```
- **Link health** (broken links, orphans) is a health signal independent of coverage.

After each cycle, the coordinator should be able to answer "did this iteration improve coverage, link health, and synthesis depth?" without reading the whole wiki.

---

## The control loop

```
Ingest → Compile → Lint ─── CLEAN → log + commit → next source
                         └─ ISSUES → contradictions? broken links? missing refs?
                                      ├─ Fixable → Compiler patches → re-lint
                                      └─ Structural → escalate to human
```

Contradictions between sources aren't always "Compiler error — fix it." Sometimes the sources genuinely disagree and the wiki should say so. The linter should flag contradictions, not silently pick a winner.

**Dynamic exit:** Two consecutive clean compiles of new sources means the compiler is in a stable rhythm — stop and move on. Stalling for a third "just to be sure" round adds nothing.

---

## Filed-back loop (the key compounding mechanism)

When the user asks a question and the answer required real research, that answer should become a permanent artifact — a new synthesis page, or an update to an existing one — not just a chat reply. Otherwise the wiki stops compounding and the same question gets re-researched in future sessions.

The coordinator's job includes noticing "this answer was expensive to compute; it should live in the wiki." It then delegates a short follow-up compilation task.

---

## QA calibration for knowledge

Calibrated few-shot examples matter here too, but the dimensions are different from software:

- **Citation integrity**: every claim in a synthesis page points to specific source pages
- **Link health**: no 404s, no orphans, no circular references without purpose
- **Contradiction handling**: where sources disagree, the wiki documents the disagreement instead of hiding it
- **Schema adherence**: pages follow the CLAUDE.md-defined structure (not invented layouts)
- **Redundancy control**: new pages don't re-state what existing pages already cover

Write 3–5 few-shot examples spanning clean and broken states for these dimensions. Generic "is this well-written?" QA is useless here; domain-specific dimensions aren't.
