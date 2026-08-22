-- nvda_tick_snapshot
--
-- A deliberately small, hardcoded, RAW tick-level slice for a demo
-- microstructure chart: NVDA only, one trading day, a 5-second
-- window (~100 trades, ~100 quotes). No aggregation/averaging of
-- any kind - genuine individual ticks.
--
-- This is intentionally NOT parameterized/general-purpose - it's a
-- purpose-built dataset sized for a clean, readable tick-level
-- Superset chart, not a reusable analytical view.
--
-- No params - just:
--   SELECT * FROM tca.nvda_tick_snapshot;

CREATE OR REPLACE VIEW tca.nvda_tick_snapshot AS
SELECT
    'quote'                          AS row_type,
    sym                              AS sym,
    time                             AS time,
    bid                              AS bid,
    ask                              AS ask,
    CAST(NULL AS Nullable(Float64))  AS price,
    CAST(NULL AS Nullable(Int64))    AS qty
FROM tca.quotes
WHERE sym = 'NVDA'
  AND time >= '2026-08-18 09:35:00.000000000'
  AND time <  '2026-08-18 09:35:05.000000000'

UNION ALL

SELECT
    'trade'                          AS row_type,
    sym                              AS sym,
    time                             AS time,
    CAST(NULL AS Nullable(Float64))  AS bid,
    CAST(NULL AS Nullable(Float64))  AS ask,
    price                            AS price,
    qty                              AS qty
FROM tca.trades
WHERE sym = 'NVDA'
  AND time >= '2026-08-18 09:35:00.000000000'
  AND time <  '2026-08-18 09:35:05.000000000';
