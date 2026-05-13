# Reference: Operations Harness (worked example)

> **Read this as an example, not a template.** Operations harnesses vary more than the other two because the task surface is more varied (issue triage, data pipeline, monitoring, incident response). Use this as a shape-reference, adapt to the actual workload.

---

## When this shape applies

You want an always-on workflow — issue triage, PR reviews, data pipelines, monitoring and response, scheduled knowledge refresh. The single-agent baseline reveals one or more of:

- Same class of task recurs frequently and the agent re-derives the same approach each time
- Patterns exist in historical outcomes that the agent doesn't use (e.g. "issues with this label were always caused by X")
- Quality drifts over time without anyone noticing until something breaks
- Human review becomes the bottleneck because the agent can't learn from past reviews

If you just want to run a one-shot task and stop, you don't need an operations harness — you need a software or knowledge harness that happens to be triggered by a cron.

---

## Typical roles

- **Coordinator** — triggered by new work (webhook, cron, queue). Classifies the incoming item, routes to the appropriate executor.
- **Executor(s)** — act on the item. Often specialized: one for labeling, one for similarity search, one for fix suggestion. Keeping them specialized makes the verifier's calibration tractable.
- **Monitor / Verifier** — independently grades each executed action. Its reports feed the experience layer.
- **Experience layer** — periodically scans past reports, extracts patterns, updates executor/verifier prompts. This is the defining feature of an operations harness.

---

## The experience layer (the defining feature)

Operations harnesses run long enough that *learning from history* becomes a first-class concern. Without an explicit learning loop, the system processes items forever without getting smarter.

```
Execution history  (reports + progress log)
       │
       ▼  periodic extraction
Two levels:
  Low-level  : "Issue #42 was fixed by doing X in file Y"        (fast replay, brittle)
  High-level : "Label-mismatch issues usually mean the titles drift from the tickets" (slow, transferable)
       │
       ▼  feed back into
Executor prompts (act better) + Verifier prompts (catch more)
```

Store the extracted patterns in an explicit experience directory — a `patterns.md` for high-level, a `replay.json` or similar for low-level. Both levels matter. Low-level is cheap and reactive; high-level is slow and transferable, and that's where the real compounding happens.

**Human curation is required.** Without periodic curation, the experience layer accumulates noise — coincidences get promoted to patterns, specific fixes get generalized beyond their actual scope. A human should review extracted patterns every so often and prune.

---

## Continuous loop — with quality-based termination, not fixed rounds

```
Detect → Classify → Execute → Verify ─── PASS → record → next item
                                      └─ FAIL → fix or escalate
                                       periodically → extract patterns → update prompts
```

The loop doesn't terminate on its own. Only a human decision stops it, or a degradation signal auto-pauses it. But within that never-stop outer loop, individual items still follow the Plan→Execute→Verify pattern, and individual items still use dynamic exit — two clean rounds on an item = done, three repetitions of the same failure = escalate.

**Frontier tracking is essential here.** Unlike a one-off software build, operations harnesses have hundreds or thousands of data points. You need a signal for "is the frontier trending up?" — e.g., verified acceptance rate over the last N items. If the trend is flat, the experience layer isn't compounding; dig in.

If the trend *degrades* below a known-good level, auto-pause and alert. This is how you prevent a bad pattern update from silently poisoning the whole pipeline.

---

## Blackboard structure for operations

```
.harness/
  spec.md                         ← pipeline definition; what's in scope, what isn't
  progress.tsv                    ← one row per processed item; frontier signal
  HANDOFF.md                      ← session-continuation note
  reports/
    {item_id}_{round}.md          ← executor + verifier per item
  experience/
    patterns.md                   ← high-level learnings (human-curated)
    failures.md                   ← modes of failure and their triggers
    replay.json                   ← low-level "item X was fixed by action Y"
```

The `experience/` directory is the difference between operations and software harnesses. Software harnesses build something and stop; operations harnesses run long enough that the harness itself must evolve from its own history.

---

## Verifier calibration for operations

Same principles as software/knowledge — few-shot examples, per-dimension thresholds, domain failure modes — but the failure modes are *highly* domain-specific and must come from real observations, not generic lists. Examples from a real GitHub issue triage harness:

- "Keyword masquerade" — a ticket mentions a keyword but isn't actually about that topic
- "Hallucinated PRs" — executor references a PR number that doesn't exist
- "Stale resolution" — executor suggests a fix from a past issue where the underlying cause has since changed
- "Confidence theater" — executor expresses high confidence on a genuinely ambiguous case

These aren't derivable from general principles. They come from reading a sample of past failures and naming the patterns. Do that extraction once, then embed the list in the verifier's prompt as explicit check targets.

---

## Source immutability is critical at scale

In operations, the input stream (incoming issues, raw events, external API responses) is append-only. The harness reads from it and writes *derivations* to its own output layer. If the executor ever writes back to the source stream — mutating issue bodies, rewriting events, editing incoming webhooks — debugging becomes impossible because the ground truth is no longer ground. Enforce this at the tool-allocation level: executors should not have write permissions on the input source.
