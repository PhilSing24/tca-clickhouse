-- effective_spread_summary(order_id)
--
-- Volume-weighted average effective spread across ALL of an order's
-- executions - the single "how much did I pay for immediacy overall"
-- number, as opposed to effective_spread_by_execution's per-fill detail.
--
-- Self-contained (duplicates the ASOF join logic from
-- effective_spread_by_execution rather than composing from it) -
-- ClickHouse does not reliably propagate parameters when one
-- parameterized view calls another. See order_scorecard.sql for the
-- full explanation of this design constraint.
--
-- Params:
--   order_id : String
--
-- Returns: orderid, sym, side, total_qty, avg_effective_spread,
--   avg_effective_spread_bps
--
-- Example:
--   SELECT * FROM tca.effective_spread_summary(order_id = 'ORD001');

CREATE VIEW IF NOT EXISTS tca.effective_spread_summary AS
WITH fills AS (
    SELECT
        e.orderid,
        e.sym,
        e.side,
        e.qty,
        2 * multiIf(e.side = 'BUY', 1, e.side = 'SELL', -1, NULL)
          * (e.price - (q.bid + q.ask) / 2)                              AS eff_spread,
        2 * multiIf(e.side = 'BUY', 1, e.side = 'SELL', -1, NULL)
          * (e.price - (q.bid + q.ask) / 2) / ((q.bid + q.ask) / 2) * 10000 AS eff_spread_bps
    FROM tca.executions AS e
    ASOF LEFT JOIN tca.quotes AS q
        ON e.sym = q.sym AND e.time >= q.time
    WHERE e.orderid = {order_id:String}
)
SELECT
    orderid,
    sym,
    side,
    sum(qty)                             AS total_qty,
    sum(eff_spread * qty) / sum(qty)     AS avg_effective_spread,
    sum(eff_spread_bps * qty) / sum(qty) AS avg_effective_spread_bps
FROM fills
GROUP BY orderid, sym, side;
