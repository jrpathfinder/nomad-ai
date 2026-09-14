# NomadTrader — Market Analysis & Product Requirements

Status: proposal · Branch: `claude/trading-app-requirements-u2788l`

---

## 1. Why this document exists

Three questions drove it:

1. What are the best and most-trending trader apps right now (AI and non-AI)?
2. What is the best iPhone trading app we could build, with a cloud backend?
3. Which currency should it be denominated in — USD, RUB, or crypto?

Section 2 answers the first, section 3 the third (it constrains everything else), and
sections 4 onward specify the product.

---

## 2. Market analysis

### 2.1 The three camps

**Retail brokerages** — Robinhood, Webull, eToro, Trading 212, Moomoo, Revolut Invest,
IBKR GlobalTrader. They own execution and distribution. Monetisation is payment-for-order-flow,
spreads, securities lending, and increasingly subscriptions. Their analytics are shallow by
design: the business model rewards trade frequency, not trader improvement.

**Crypto exchanges** — Binance, Bybit, OKX, Coinbase, Kraken, Bitget. The growth features of the
last two years have been copy trading, perpetuals, and points/airdrop campaigns rather than
better analysis. Mobile apps are order-entry terminals with a chart bolted on.

**"AI trading" apps** — Composer, Tickeron, Danelfin, Magnifi, Trade Ideas, and a long tail of
GPT-wrapper screeners. This is where the hype is and where the retention isn't. Two recurring
failure modes:

- **Opaque signals.** The app emits buy/sell calls with no auditable derivation. Users cannot
  verify them, reviewers distrust them, and regulators treat them as advice.
- **A chatbot with no grounding.** An LLM answering general market questions is a worse Google.
  It does not know your positions, your cost basis, or your history, so it cannot say anything
  you could act on.

### 2.2 What is actually growing

Copy/social trading, prediction markets, options for retail, prop-firm / funded-trader apps,
and — relevant to us — **trading education and simulation**. The simulator category is
consistently underrated: it has no custody, no licensing, no execution risk, and the users who
stick are exactly the ones who later want a real account.

### 2.3 The gap we are aiming at

> No app is a copilot that is genuinely grounded in **your own positions and your own trading
> history**, and honest about what it does not know.

Two design commitments follow, and they are the product:

1. **Numbers are computed deterministically in Java; the LLM only explains them.** Indicators,
   P&L, backtest metrics, and behavioural statistics all come from tested pure functions. An LLM
   asked to compute RSI from a candle array, or win-rate-after-a-loss from 200 trade rows, gets
   it wrong a meaningful fraction of the time — and the credibility of everything else collapses
   with it.
2. **The AI proposes; the user disposes.** The model can draft an order or an alert, but the tool
   returns a proposal object, never an execution. The app renders a confirmation card. Nothing
   happens until a human taps.

---

## 3. Currency decision: crypto, denominated in USDT

|                      | **Crypto (USDT)** | USD stocks | RUB / MOEX |
|----------------------|-------------------|------------|------------|
| Real-time market data | Free WebSocket from Binance/Bybit/OKX | Paid + exchange display agreements | Licensed vendors, limited |
| Licence to operate    | None for analysis + paper trading | Broker-dealer / RIA questions arise quickly | Local regulatory exposure |
| App Store risk        | Low with no custody and no execution | Trading apps are expected from registered institutions | RU fintech distribution restricted; RuStore instead |
| Market hours          | 24/7 — an always-on app | ~6.5h/day, dead weekends | Limited, single venue |
| Audience              | Global | Global but gated | One country |

**Decision: crypto-first, everything denominated in USDT (treated as ≈ USD).**

Crypto is the only one of the three where a small team gets **real-time data and a working
product in weeks with no licence**. The 24/7 market also matters more than it first appears:
alerts, live strategies, and push notifications all have something to do at 3am, which is what
makes a mobile app worth keeping installed.

USD equities are a **phase-2 expansion** once there are users — via SnapTrade or Alpaca for
read-only account linking, which is a data-partnership problem rather than a licensing one.
RUB is a distribution dead end for an App Store app and is explicitly out of scope, though the
UI ships **Russian and English from day one** because the audience is there regardless of venue.

---

## 4. Product scope (v1)

**In scope**

- Live crypto market data, watchlists, candlestick charts.
- **Paper trading** with realistic fills, fees and slippage.
- **Portfolio copilot** — chat grounded in the user's actual positions and live data.
- **Strategy builder in plain language** — described in words, compiled to a validated rule spec,
  backtested honestly, then runnable as live alerts.
- **News and sentiment digest** with push alerts that explain *why* something moved.
- **Trade journal and discipline coach** — detects behavioural leaks from real trade data.
- English and Russian throughout, including server-generated text.

**Explicitly out of scope for v1**

- No custody of funds. No real order execution. No fiat on/off ramps. No margin or leverage.
- No exchange API keys stored in v1 (read-only account sync is a later, separate decision).

This boundary is not caution for its own sake — it is what keeps the app out of broker-dealer
territory and out of the App Store rules that apply to apps facilitating real transactions.

---

## 5. Architecture summary

### Backend — Spring Boot 4 / Java 21, new packages under `com.nomad.ai.trading.*`

Single Maven module. The scaffold is empty, so a multi-module split would cost four poms and
buy nothing while there is one deployable. The one real future pressure is that market-data
ingestion must be a **single process** (one shared upstream exchange connection) while the API
tier scales horizontally — handled with `@Profile("ingest")` on the connectors, same jar, two
deployments.

Packages: `config`, `auth`, `marketdata`, `stream`, `strategy`, `backtest`, `paper`, `ai`,
`alerts`, `news`, `journal`, `push`, `api`, `common`.

### Storage — plain Postgres 16 + Flyway

50 symbols x 1m candles x 2 years is roughly 53M rows. A composite primary key plus a BRIN index
handles that on a 2-vCPU box, and the dominant query is a contiguous range scan by
`(symbol, interval, open_time)` — exactly what a clustered composite btree serves best.
TimescaleDB's compression and continuous aggregates are not load-bearing until we store raw
ticks. Every candle read goes behind a `CandleStore` interface so the migration is one class
plus a Flyway script.

Two decisions make plain Postgres sufficient:

- **Only closed 1-minute klines are persisted.** Persisting an unclosed kline writes wrong OHLC
  that then poisons every backtest over that period. Ticks never reach the database.
- **Higher timeframes are derived on read**, not stored — a 6x storage saving that also removes
  the class of bug where a 4h candle disagrees with its own 1m candles.

`numeric(24,10)` for prices, `BigDecimal` in Java. A `double` anywhere in a P&L path is a
support ticket nobody can reproduce.

### Real-time delivery

A plain WebSocket at `/ws/market` (not STOMP — iOS speaks raw frames, and topic routing is a
`ConcurrentHashMap`). Auth travels as the **first frame, not a query parameter**, because query
strings land in access and proxy logs. Quotes are **coalesced to 4 messages/sec/symbol**: raw
Binance trade streams run to hundreds per second, and forwarding those to a phone drains the
battery for nothing the eye can see.

### AI layer

Provider switches from the OpenAI starter to **Anthropic**, primarily for **prompt caching** —
the system prompt plus thirteen tool schemas is 2–4k tokens on every single turn, and cache
control drops that to roughly a tenth. The iOS codebase already targets Claude, so it is also
one key and one billing line.

Everything goes behind our own `LlmClient` interface with a single implementation class. Spring
AI is on a **milestone release (2.0.0-M3)**; milestone APIs drift, and this confines the blast
radius to one file.

Chat streams to the app over **SSE**, not the market WebSocket — it is per-request, so cancelling
is just cancelling a Swift `Task`, and it needs no correlation IDs.

### iOS — `ios/NomadTrader/`, generated by XcodeGen

Sibling to `ios/NomadInventory/`, which is untouched. XcodeGen replaces the hardcoded-path
`sync_to_xcode.sh` copy script, which is unworkable at ~50 Swift files and makes iOS CI
impossible today.

Tabs: **Markets · Portfolio · Copilot · Strategies · More**. Journal and Coach live inside
Portfolio as a segmented control — they are derived from paper fills, and tab bars degrade past
five items.

**No SwiftData, unlike NomadInventory.** That app is local-first; the inventory *is* the device's
data. This one inverts that — the server is authoritative for every entity because it keeps
running while the phone is in a pocket: limit orders fill, alerts fire, strategies evaluate. A
small disk-cache actor covers offline reads.

Tokens live in the **Keychain**, and the Settings screen has **no API key field at all** — the
deliberate correction of `ios/NomadInventory/Services/AIService.swift`, which today reads an
Anthropic key from `UserDefaults` and calls the provider straight from the device. All provider
keys stay on the backend.

---

## 6. The two safety-critical designs

### 6.1 Strategy specs are a closed AST, never code

Plain-language input is compiled by the LLM into a **declarative JSON AST** with a whitelisted
vocabulary: twelve indicator types, seven comparison operators, four operand kinds. Strict
Jackson deserialisation over a sealed hierarchy rejects anything unrecognised at parse time, and
a hand-written `SpecValidator` then enforces resource bounds (at most 10 indicators, tree depth
8, 40 nodes, 5 symbols, indicator periods 1–500, leverage fixed at 1.0).

There is **no code execution path** — no `eval`, no scripting engine, no SpEL over user input.
The evaluator is a `switch` over a sealed interface, so the set of things a strategy can do is
fixed at compile time.

Two consequences worth stating plainly:

- **The validator, not the model, is the security boundary.** LLM output is treated as hostile
  input from an anonymous user.
- **Back-translation to text is deterministic**, so the confirmation screen describes the rules
  that will actually run — not a second model's paraphrase of them.

### 6.2 Backtests are built to disappoint

A backtest that flatters is worse than no backtest. Look-ahead bias is prevented *structurally*
rather than by convention: the bar window handed to the evaluator is immutable and **throws on
any future index**, so a look-ahead bug is a failing test rather than an inflated Sharpe ratio.
Signals compute on bar close and fill at the **next bar's open**. When a stop and a target fall
inside the same bar, the stop wins.

Against overfitting, the defences are mostly honesty in the UI:

- A **70/30 in-sample / out-of-sample split shown side by side** by default. A strategy that
  looks brilliant in-sample and terrible out-of-sample is the most educational output this
  product can produce.
- Fees (10bps) and slippage (5bps) are on by default and **cannot be set to zero**.
- Under 30 trades, Sharpe and win rate are greyed out as an insufficient sample. Never annualise
  from under 90 days.
- Max drawdown and worst trade are rendered as prominently as total return.
- After five parameter tweaks on the same symbol and range, the app says so: that is curve
  fitting, check the out-of-sample column.

---

## 7. Milestones

| | Deliverable | Demo |
|---|---|---|
| **M0** | Repo plumbing: Maven wrapper fix, `.gitignore`, Postgres compose, Dockerfile, CI | `./mvnw -B verify` passes; health endpoint green |
| **M1** | **Live tick to screen** — Binance connector, Postgres, REST + WebSocket, chart | BTC/ETH ticking, 1m candle forming live; kill upstream, watch reconnect and backfill |
| **M2** | Auth + paper trading — Sign in with Apple, JWT rotation, matching engine | Paper buy, unrealized P&L moves with price; limit sell fills on cross |
| **M3** | Copilot — Anthropic swap, tool grounding, SSE streaming, proposal cards | Ask in Russian why ETH is down; tool chips fire, answer streams, disclaimer appears |
| **M4** | Strategy builder + backtest engine | Describe an RSI/EMA strategy in words, confirm the rendered rules, run a 2-year backtest |
| **M5** | Alerts, news, APNs push | "Alert me if BTC drops 3% in an hour" → localised push with a one-line explanation |
| **M6** | Journal, coach, live strategies | Seed trades with a revenge-trading pattern; the coach names it and cites the trades |

M1 is deliberately the smallest slice that exercises **every** layer end to end.

---

## 8. Known blockers in the current repo

Verified, and all of them block M1:

1. **`./mvnw` does not run.** It reads `.mvn/wrapper/maven-wrapper.properties`, which does not
   exist in this repo.
2. **Spring AI 2.0.0-M3 is a milestone release** and `pom.xml` has no `<repositories>` block.
   Milestones are not on Maven Central.
3. **`spring-boot-starter-data-jpa` is on the classpath with no JDBC driver and no datasource**,
   so the application cannot start today.
4. **No root `.gitignore`** — `target/`, `.env`, and APNs `.p8` keys are all currently
   commitable. This is how signing keys leak.
5. **`ai.openai.api-key` in `application.yaml` is the wrong property path.** Spring AI reads
   `spring.ai.openai.api-key`, so that placeholder was never wired to anything. Delete it rather
   than porting the mistake.
6. **Two Spring AI model starters cannot coexist unqualified** — replace the OpenAI starter with
   the Anthropic one rather than adding it, or `ChatClient.Builder` injection becomes ambiguous
   and startup fails.

---

## 9. Principal risks

**App Store review.** A finance app with an AI discussing markets is a review-risk cluster.
Mitigations: position it as education and simulation in the review notes verbatim (no custody,
no execution, no fiat rails); an unmissable "PAPER TRADING — SIMULATED" banner on the portfolio,
the order ticket, and the store screenshots, because reviewers decide what an app is in about
ninety seconds; an onboarding disclaimer with a recorded acknowledgement, as a screen rather than
a dismissible toast; and account deletion shipped in M2, since it is a common rejection. No
"signals", no "profitable strategies", no performance claims in the listing.

**Exchange IP bans.** Binance escalates rate-limit violations to an **IP ban of two minutes to
three days**, and every user shares the server's IP. The defence is architectural: **one shared
upstream connection per symbol set, never one per user** — a per-user model gets banned at around
fifty users. Plus a token bucket at 60% of the published limit, shedding load when the reported
used-weight header passes 70%, single-threaded weight-budgeted historical backfill, and a circuit
breaker on ban responses. Some hosting regions are geoblocked, so the deployment region is a
deliberate choice and the exchange stays a config value.

**The AI appearing to give investment advice.** The disclaimer is appended **server-side after
the stream completes**, localised — so the model cannot omit it, be prompt-injected out of it, or
lose it on a truncated response. The proposal tools cannot execute. Language discipline is
enforced in the system prompt and the UI copy: "conditions met on your rule", never "buy signal";
"what the data currently shows", never "will go up". Every AI input and output is logged with its
model ID, because if someone claims the app told them to do something, the transcript is the only
defence.

---

## 10. Open questions

- Monetisation: subscription tiers map cleanly onto the existing per-user AI token budget, but
  any paid tier must use StoreKit in-app purchase.
- Read-only exchange account sync (phase 2) — meaningfully stickier than paper trading, but it
  introduces API-key custody and deserves its own decision.
- US equities via SnapTrade or Alpaca as the phase-2 market expansion.
