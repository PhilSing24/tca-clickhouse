-- twap(symbol, start_time, end_time)
--
-- Time-weighted average price - gives equal weight to each time
-- interval, regardless of trading volume (unlike VWAP).
--
-- SIMPLIFICATION: this averages the quoted mid-price at each quote
-- update within the window, rather than performing a true continuous
-- time-integral (duration-weighted) average. Since our simulator's
-- quote update rate is roughly uniform through the window (see
-- di.simtick's quoteupdaterate), sampling-average and true integral
-- stay close in practice. A stricter true continuous TWAP would
-- duration-weight each quote by how long it was the prevailing quote
-- before being superseded - deferred as a refinement if ever needed.
--
-- Params:
--   symbol     : String
--   start_time : DateTime64(9, 'UTC')
--   end_time   : DateTime64(9, 'UTC')
--
-- Returns: sym, twap, quote_count
--
-- Example:
--   SELECT * FROM tca.twap(
--     symbol = 'NVDA',
--     start_time = '2026-01-20 09:35:00.000000000',
--     end_time   = '2026-01-20 09:45:00.000000000'
--   );

CREATE OR REPLACE VIEW tca.twap AS
SELECT
    sym,
    avg((bid + ask) / 2) AS twap,
    count() AS quote_count
FROM tca.quotes
WHERE sym = {symbol:String}
  AND time >= {start_time:DateTime64(9, 'UTC')}
  AND time <= {end_time:DateTime64(9, 'UTC')}
GROUP BY sym;
