-- full_day_vwap(symbol, date)
--
-- Volume-weighted average trade price across the ENTIRE trading day,
-- as opposed to interval_vwap which is scoped to a specific execution
-- window. A coarser benchmark: "how did my execution compare to the
-- whole day's activity" rather than just the period I was trading.
--
-- Params:
--   symbol : String
--   date   : Date
--
-- Returns: sym, vwap, trade_count
--
-- Example:
--   SELECT * FROM tca.full_day_vwap(
--     symbol = 'NVDA',
--     date = '2026-01-20'
--   );

CREATE VIEW IF NOT EXISTS tca.full_day_vwap AS
SELECT
    sym,
    sum(price * qty) / sum(qty) AS vwap,
    count() AS trade_count
FROM tca.trades
WHERE sym = {symbol:String}
  AND toDate(time) = {date:Date}
GROUP BY sym;
