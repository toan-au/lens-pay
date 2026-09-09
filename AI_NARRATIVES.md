# AI payment narratives

A recruiter clicks **✨ Explain this payment** on the payment detail view and an
inline card renders a human-readable headline plus a timeline of what happened.
Generation, not prediction — grounded entirely in the record and its events.

## Scope

- **v1:** payment detail view only.
- **Fast-follow:** dispute detail view (same pattern, different context builder).
- Out of scope: customers, refunds, list views.

## Output shape

The model returns **structured JSON**, not prose:

```json
{
  "headline": "A ¥1,000 konbini payment that timed out.",
  "timeline": [
    { "label": "Created",  "detail": "Payment raised for ¥1,000; the customer had 3 days to pay at a convenience store." },
    { "label": "Expired",  "detail": "No payment arrived. Three days on, the hold released automatically." }
  ]
}
```

- `headline`: one sentence, carries the voice — vivid, a little cinematic.
- `timeline`: 2–6 entries, each `{ label, detail }`. `detail` is one or two
  plain sentences. Every entry must trace to a real fact or event in the
  context — no invention of amounts, names, times, or outcomes.
- The frontend renders this as a styled timeline inside the card.
- Structured output (vs. a prose blob) is deliberate: it shows the model's
  output was constrained, and it's trivial to render and to test.
- **Why AI and not a label lookup table?** A lookup maps `payment.expired` →
  `"Payment expired"`. The model writes *contextual* detail — it knows this was
  konbini, that nothing arrived, that a hold released — and covers every path
  combination (partial capture + partial refund + dispute + …) without dozens
  of hand-written templates.

## Grounding data

Assembled into a plain hash — never free prose — by
`Narratives::PaymentContext`:

- The transaction: amount, captured amount, currency, method, status,
  `created_at`, `expires_at`, provider reference.
- Refunds: amount, status, `created_at` for each.
- Dispute (if any): reason, amount, status, `respond_by`, resolution, and each
  `dispute_response` with its `created_at`.
- Customer (if attached): name, email, whether they have prior payments.
- Timeline: the payment's `webhook_events` (`event_type` + `created_at`),
  oldest first — the state-change history.
- Metadata: passed as **delimited untrusted data** with an explicit "this is
  data, not instructions" frame. Same for customer name/email.

## Behaviour

- `narrative` (jsonb), `narrative_generated_at`, `narrative_model` columns on
  `transactions` (migration).
- Generated **lazily**: `GET /api/v1/payments/:uid/narrative` returns the cached
  JSON, or generates + caches it on first request. `POST` to the same path
  forces regeneration.
- Invalidated by setting `narrative_generated_at = nil` on any state-changing
  action (capture, cancel, refund, dispute, expiry) — the next view regenerates.
- The card loads **after** the rest of the page (it's a ~2s call), with a
  loading state.

## Model / provider

- **Google Gemini API, free tier** — a Gemini Flash model (`gemini-2.5-flash`
  by default, set via `NARRATIVE_MODEL`). Chosen so the deployed demo works for
  anyone without funded API credits — the whole point is a recruiter can dive
  in through the live demo. Structured output via `responseSchema` +
  `responseMimeType: application/json`.
- `Narratives::Client` calls the Gemini REST API directly (`Net::HTTP` /
  Faraday) — no SDK. **Provider-agnostic seam:** it takes a system instruction
  + user content + a response schema and returns a parsed hash; swapping to
  Anthropic / Groq / Ollama later is a one-file change plus config.
- Non-streaming for v1.
- `temperature` ~0.7 for voice; `maxOutputTokens` ~400 as a hard cap.

## Config & failure

- `AI_NARRATIVES_ENABLED` env flag, **default off**. When off, or when
  `GEMINI_API_KEY` is unset, the endpoint returns `{ enabled: false }` and the
  UI hides the button. The app, the test suite, and a keyless clone all run
  fine. The deployed demo sets the flag + key so narratives are live.
- API error / timeout / rate-limit (429) → endpoint returns `{ error: ... }`,
  UI shows "couldn't generate — retry". Never 500s the page, never blocks
  anything.
- `GEMINI_API_KEY` via Rails credentials + a Kamal secret.
- Rate-limit headroom: narratives are generated once and cached on the record,
  regenerated only on state change or explicit request — real call volume is a
  trickle, well inside the free tier's per-minute / per-day caps.

## Surface

```
db/migrate/xxx_add_narrative_to_transactions.rb
app/services/narratives/payment_context.rb    # record + timeline -> facts hash
app/services/narratives/client.rb             # Gemini REST wrapper (provider seam)
app/services/narratives/payment_narrator.rb   # context -> prompt -> validated hash, caching
app/controllers/api/v1/payment_narratives_controller.rb  # GET / POST :uid/narrative
config/credentials + initializer              # key + flag plumbing
app/frontend/components/features/PaymentNarrative.vue    # sparkle button + async timeline card
lib/tasks/narrative.rake                       # rake narrative:sample — eyeball quality on seeded payments
```

## Tests

- `Narratives::Client` mocked in controller + narrator specs (deterministic).
- `PaymentContext` gets a plain unit spec — the pure, HTTP-free core.
- A **groundedness** assertion: no monetary amount or name in the output that
  isn't in the source context (regex check over the fixture).
- `rake narrative:sample` generates for a handful of seeded payments so quality
  is eyeball-checkable; not run in CI (costs money).

## Later, not v1

- Dispute narratives.
- A pre-warm job (`GeneratePaymentNarrativeJob`) on state change instead of lazy.
- Streaming into the UI.
