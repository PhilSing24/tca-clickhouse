-- arrival_price(symbol, ts)
--
-- Returns the mid price at a given instant for a given symbol - the
-- standard "arrival price" benchmark used as the reference point for
-- implementation shortfall.
--
-- Self-contained (does not compose prevailing_quote) so it has no
-- dependency on parameterized-view nesting behavior.
--
-- Params:
--   symbol : String                  - e.g. 'NVDA'
--   ts     : DateTime64(9, 'UTC')    - the instant to price (e.g. order starttime)
--
-- Returns: sym, time, arrival_price
--
-- Example:
--   SELECT * FROM tca.arrival_price(
--     symbol = 'NVDA',
--     ts = '2026-01-20 09:35:00.000000000'
--   );

CREATE OR REPLACE VIEW tca.arrival_price AS
SELECT
    sym,
    time,
    (bid + ask) / 2 AS arrival_price
FROM tca.quotes
WHERE sym = {symbol:String}
  AND time <= {ts:DateTime64(9, 'UTC')}
ORDER BY time DESC
LIMIT 1;
