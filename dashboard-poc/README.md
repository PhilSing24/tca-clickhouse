# TCA Dashboard Prototype (Dash/Plotly)

A working proof-of-concept dashboard built after Superset's time-series chart types
proved unable to render tick-level data without forced aggregation (see the
handoff email for details). Connects directly to ClickHouse, three tabs:

- **Tick-Level View** — bid/ask channel with individual trade and execution
  markers (good=green, bad=red), fully filterable by symbol and time window
- **Order Scorecard** — sortable, color-coded table of all orders' cost vs.
  each of the 6 benchmarks
- **Average Cost by Symbol** — grouped bar chart comparison

This is a proof of concept, not a production app - built to test whether the
tick-level visualization problem was solvable outside Superset. It was.

## Setup

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Run

Requires a running ClickHouse instance with the `tca` database populated
(see the parent repo's `schema/` and `scripts/ingest.sh`).

```bash
python app.py
```

Then open http://localhost:8050
