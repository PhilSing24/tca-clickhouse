-- pwp(symbol, start_time, end_time)
--
-- Participation-Weighted Price: the price a hypothetical strategy
-- trading at a CONSTANT percentage of market volume would have
-- achieved over the window.
--
-- SIMPLIFICATION - IMPORTANT: under a constant-participation-rate,
-- no-market-impact assumption, PWP is mathematically IDENTICAL to
-- interval_vwap - a strategy taking a fixed % of every trade in the
-- window achieves, by construction, the same volume-weighted average
-- price as the market itself. This view is therefore currently the
-- same computation as interval_vwap, kept as its own named view so
-- reports can label/reference "PWP" explicitly.
--
-- PWP only becomes genuinely DIFFERENT from VWAP once either of these
-- is modeled (neither is modeled today):
--   - non-constant participation (e.g. only active part of the window)
--   - market impact (the hypothetical strategy's own trading shifting
--     subsequent market prices)
--
-- Params:
--   symbol     : String
--   start_time : DateTime64(9, 'UTC')
--   end_time   : DateTime64(9, 'UTC')
--
-- Returns: sym, pwp, trade_count
--
-- Example:
--   SELECT * FROM tca.pwp(
--     symbol = 'NVDA',
--     start_time = '2026-01-20 09:35:00.000000000',
--     end_time   = '2026-01-20 09:45:00.000000000'
--   );

CREATE VIEW IF NOT EXISTS tca.pwp AS
SELECT
    sym,
    sum(price * qty) / sum(qty) AS pwp,
    count() AS trade_count
FROM tca.trades
WHERE sym = {symbol:String}
  AND time >= {start_time:DateTime64(9, 'UTC')}
  AND time <= {end_time:DateTime64(9, 'UTC')}
GROUP BY sym;
