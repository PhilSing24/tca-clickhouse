-- close_price(symbol, date)
--
-- Closing price benchmark: "would waiting until end of day have been
-- better?"
--
-- SIMPLIFICATION: real markets set an official closing price via a
-- closing auction (e.g. NASDAQ Closing Cross), a distinct trade that
-- occurs AFTER continuous trading ends and can differ meaningfully
-- from the last continuous-session print. di.simtick has no closing
-- auction mechanism - it's continuous simulated trading with no
-- special end-of-day event - so "close" here is simply the last
-- trade of the simulated day. If real tick data is ever ingested,
-- the trades table would need a sale-condition-style field to
-- correctly identify the actual auction print rather than relying
-- on chronological order.
--
-- Params:
--   symbol : String
--   date   : Date
--
-- Returns: sym, time, close_price
--
-- Example:
--   SELECT * FROM tca.close_price(
--     symbol = 'NVDA',
--     date = '2026-01-20'
--   );

CREATE VIEW IF NOT EXISTS tca.close_price AS
SELECT
    sym,
    time,
    price AS close_price
FROM tca.trades
WHERE sym = {symbol:String}
  AND toDate(time) = {date:Date}
ORDER BY time DESC
LIMIT 1;
