-- effective_spread_by_execution(order_id)
--
-- Effective spread for EACH execution of an order - how far the fill
-- price landed from the prevailing mid at that instant, doubled per
-- the standard convention (round-trip cost vs. the quoted spread).
--
-- effective_spread    = 2 * direction * (fill_price - mid)
-- effective_spread_bps = 2 * direction * (fill_price - mid) / mid * 10000
--
-- direction = +1 for BUY, -1 for SELL, so positive always means
-- "paid away from mid" (cost) regardless of side - same sign
-- convention as slippageBps.
--
-- Uses ASOF JOIN to find the prevailing quote at/before each fill's
-- timestamp. Self-contained (not composed from prevailing_quote or
-- other parameterized views) for the same reliability reason as
-- order_scorecard - see that file's design note.
--
-- Params:
--   order_id : String
--
-- Returns: one row per execution - orderid, execid, sym, side, time,
--   fill_price, qty, bid, ask, mid, effective_spread, effective_spread_bps
--
-- Example:
--   SELECT * FROM tca.effective_spread_by_execution(order_id = 'ORD001');

CREATE OR REPLACE VIEW tca.effective_spread_by_execution AS
SELECT
    e.orderid,
    e.execid,
    e.sym,
    e.side,
    e.time,
    e.price AS fill_price,
    e.qty,
    q.bid,
    q.ask,
    (q.bid + q.ask) / 2 AS mid,
    2 * multiIf(e.side = 'BUY', 1, e.side = 'SELL', -1, NULL)
      * (e.price - (q.bid + q.ask) / 2)                              AS effective_spread,
    2 * multiIf(e.side = 'BUY', 1, e.side = 'SELL', -1, NULL)
      * (e.price - (q.bid + q.ask) / 2) / ((q.bid + q.ask) / 2) * 10000 AS effective_spread_bps
FROM tca.executions AS e
ASOF LEFT JOIN tca.quotes AS q
    ON e.sym = q.sym AND e.time >= q.time
WHERE e.orderid = {order_id:String};
