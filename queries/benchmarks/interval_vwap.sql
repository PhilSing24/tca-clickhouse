-- interval_vwap(symbol, start_time, end_time)
--
-- Volume-weighted average trade price for a symbol over a bounded time
-- window - the standard market VWAP benchmark. Always requires a
-- symbol and a bounded time range so this stays a partition/index-
-- pruned query regardless of total table size.
--
-- Params:
--   symbol     : String
--   start_time : DateTime64(9, 'UTC')
--   end_time   : DateTime64(9, 'UTC')
--
-- Returns: sym, vwap, trade_count
--
-- Example:
--   SELECT * FROM tca.interval_vwap(
--     symbol = 'NVDA',
--     start_time = '2026-01-20 09:35:00.000000000',
--     end_time   = '2026-01-20 09:45:00.000000000'
--   );

CREATE VIEW IF NOT EXISTS tca.interval_vwap AS
SELECT
    sym,
    sum(price * qty) / sum(qty) AS vwap,
    count() AS trade_count
FROM tca.trades
WHERE sym = {symbol:String}
  AND time >= {start_time:DateTime64(9, 'UTC')}
  AND time <= {end_time:DateTime64(9, 'UTC')}
GROUP BY sym;
