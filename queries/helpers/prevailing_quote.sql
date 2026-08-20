-- prevailing_quote(symbol, ts)
--
-- Returns the most recent quote at or before a given timestamp for a
-- given symbol. This is the core "ASOF lookup" primitive that every
-- price-relative-to-market benchmark is built on.
--
-- Params:
--   symbol : String                  - e.g. 'NVDA'
--   ts     : DateTime64(9, 'UTC')    - the instant to look up
--
-- Returns: sym, time, bid, ask, bidsize, asksize, mid
--
-- Example:
--   SELECT * FROM tca.prevailing_quote(
--     symbol = 'NVDA',
--     ts = '2026-01-20 09:35:00.000000000'
--   );

CREATE OR REPLACE VIEW tca.prevailing_quote AS
SELECT
    sym,
    time,
    bid,
    ask,
    bidsize,
    asksize,
    (bid + ask) / 2 AS mid
FROM tca.quotes
WHERE sym = {symbol:String}
  AND time <= {ts:DateTime64(9, 'UTC')}
ORDER BY time DESC
LIMIT 1;
