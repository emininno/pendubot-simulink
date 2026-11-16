# BONK / Ar2Y — Market-Data Signal Assessment

**Status:** Preliminary technical assessment (Phase A)  
**Scope:** Historical data processing and trading-decision analysis; no live trading or Rust deployment.  
**Confidential:** Project materials and the reference wallet identity must remain within the authorized team.

## 1. Problem

**BONK** is an already-profitable trading bot operating on tokens that migrate from **pump.fun** bonding curves to **PumpSwap**. A reference bot, **Ar2Y**, reportedly performs better under broadly comparable conditions. We want to determine whether the observable market-data stream contains **additional signals, features, or decision rules** that BONK does not currently exploit.

This is **not** a copy-trading project. Acting after Ar2Y's published buy/sell transactions loses the advantage to latency and execution costs. Ar2Y's trades are evidence to investigate, not signals to follow mechanically.

**Market universe:** PumpSwap token/SOL pools created by pump.fun migration (`poolCreatedBy = pump`); exclude manually created (`custom`) pools. The relevant trades typically enter seconds to minutes after migration and exit on a short horizon.

We assume comparable operating conditions for the initial study, but must verify this before attributing performance differences to decision logic.

## 2. Reference observations (provided, not independently verified)

Reference wallet: `Ar2Y6o1QmrRAskjii1cRfijeKugHH13ycxW5cd7rro1x`

For **3–13 October 2026**, the supplied analysis of on-chain balances reports:

| Metric | Reported value |
| --- | --- |
| Completed buy/sell cycles | ~1,700/day |
| Median trade size | ~1.6 SOL |
| Mean ROI per cycle | +1.05% (+1.26% size-weighted) |
| Median daily PnL | ~+41 SOL; 9 positive days out of 11 |
| Median holding period | 47 seconds (middle half: ~14 seconds to 7 minutes) |

The source also reports **+2.2% mean ROI** for individually verified September cycles. Delayed imitation of Ar2Y trades reportedly loses ~4% per trade.

These values describe **Ar2Y**, not BONK; a comparable BONK decision/trade/PnL baseline has not yet been supplied.

## 3. Available data and code

- **Historical replay:** PumpAPI hourly compressed JSONL files: `https://replay.pumpapi.io/YYYY/MM/DD/HH.jsonl.zst`. Example daily index: `https://replay.pumpapi.io/2026/10/10/`.
- **Volume:** approximately 14 GB/day compressed, according to the supplied notes. `curl` worked for the original team; their `urllib` requests returned HTTP 403.
- **Coverage analyzed:** 3 October 00:00 through 13 October 13:00 UTC, 2026; the supplied CatBoost experiment uses **10, 11 and 12 October only**.
- **Event fields:** signature, signer, mint, amounts, pool/virtual reserves, price, pool fee, before/after balances, address lookup tables, program usage and millisecond timestamps.
- **Ar2Y cycles:** `dati/ar2y_cicli_sol_0310_1310.parquet` (included in the supplied archive), with entry/exit times, market-cap values, SOL in/out, ROI, etc.

Supplied Python pipeline (under `codice/` in the source archive):

| Script | Purpose |
| --- | --- |
| `01_download.py` | Download hourly replays |
| `02_slim.py` | Convert selected pump.fun/PumpSwap events to Parquet |
| `02_ar2y_rows.py` | Extract Ar2Y-related transaction rows |
| `04_ar2y_cycles.py` | Reconstruct buy/sell cycles from on-chain balances |
| `04_ar2y_ablation_ds.py` | Build per-token, per-second decision samples and features; label whether Ar2Y buys within 15 seconds |
| `05_ar2y_ablation_train.py` | Train/evaluate a CatBoost Ar2Y-entry classifier |

The supplied code uses machine-specific data paths that will need configuring before reproduction. The intermediate model-training Parquet files are **not** included; the full replay can be downloaded if needed. See the model results in `codice/05_ar2y_ablation_train.txt`.

## 4. Existing research baseline — useful but insufficient

The **CatBoost model is a research baseline for predicting Ar2Y entries**, **not** the production BONK strategy or its economic baseline.

- It evaluates **43 base** and **39 additional** features; first entries and re-entries are considered separately.
- The model reports AUC around **0.93–0.96** for first-entry / combined classifications (re-entry AUC is around **0.81–0.82**).
- Despite recognizing broad entry conditions, the reported precision and recall do **not** satisfy the stated operational target of **at least 40% precision at 30% recall**.
- Direct prediction of the team's own trading outcomes, using hand-built indicators, a transformer and automatically generated indicators, reportedly achieved weak rank correlations (~0.15–0.25), insufficient after costs.

**Methodology to check before reuse:** the three-day cross-validation trains on the other two days (not a strictly forward-only test), and some operating thresholds are identified using labels from the evaluated fold. Performance per decision row must also be distinguished from performance per distinct actionable signal and from net trading PnL.

A high classification AUC is **not** evidence of a profitable improvement to BONK.

## 5. Existing execution-cost assumptions

The supplied backtest approximation, calibrated by the original team against actual fills, uses:

- **Execution price:** last observed print at or before **decision time +150 ms**, on both entry and exit; never select the best price in a future window.
- **Fees:** 1.25% per side (`poolFeeRate`) plus **0.00113 SOL per completed cycle**.
- **Price impact:** constant-product approximation with effective SOL reserve `Q = quoteInPool + virtualQuoteInPool`; buy multiplier `1 + size/Q`, sell multiplier `Q/(Q + value_sold)`.
- **Position rule:** at most one open position per token; re-entry is allowed after exit.

For an approximately **100 SOL** effective reserve just after migration, the source estimates round-trip friction of ~**3.5% at 0.3 SOL** and ~**4.6% at 1 SOL**, before any adverse move during the delay. These are **source assumptions**, not independently verified economics; validate against BONK's real executions.

## 6. Approach and current boundary

**Phase A — Assess before committing:** confirm the actual comparison, review inputs and prior tests, identify missing evidence, perform at most a narrowly time-boxed offline feasibility check, and decide whether deeper research is justified. **See [`TECH_PLAN.md`](TECH_PLAN.md) for the short actionable checklist and material requests.**

**Phase B — Research only after authorization:** investigate candidate market-stream features and decision rules, validate chronologically out-of-sample against **BONK's own net-PnL baseline**, and only then consider integration with the team's Rust execution system.

**Immediate next step:** complete the requests and minimal audit in `TECH_PLAN.md`. Do not start large downloads, a broad model-search campaign or a production implementation yet.
