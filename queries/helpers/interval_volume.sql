-- interval_volume(symbol, start_time, end_time)
--
-- Total traded volume (shares) for a symbol over a bounded time window.
-- Used for participation-rate calculations (your order's qty as a
-- fraction of total market volume over the same window).
--
-- Params:
--   symbol     : String
--   start_time : DateTime64(9, 'UTC')
--   end_time   : DateTime64(9, 'UTC')
--
-- Returns: sym, total_volume, trade_count
--
-- Example:
--   SELECT * FROM tca.interval_volume(
--     symbol = 'NVDA',
--     start_time = '2026-01-20 09:35:00.000000000',
--     end_time   = '2026-01-20 09:45:00.000000000'
--   );

CREATE OR REPLACE VIEW tca.interval_volume AS
SELECT
    sym,
    sum(qty) AS total_volume,
    count() AS trade_count
FROM tca.trades
WHERE sym = {symbol:String}
  AND time >= {start_time:DateTime64(9, 'UTC')}
  AND time <= {end_time:DateTime64(9, 'UTC')}
GROUP BY sym;
