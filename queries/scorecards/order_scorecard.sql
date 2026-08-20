-- order_scorecard(order_id)
--
-- The full per-order TCA scorecard: execution VWAP compared against
-- all 6 benchmarks, as both raw prices and signed slippage in bps.
--
-- DESIGN NOTE: this is deliberately SELF-CONTAINED rather than
-- composed from the separate views in queries/benchmarks/ and
-- queries/orders/. ClickHouse's parameterized views do not reliably
-- propagate parameters when one parameterized view calls another
-- (confirmed via ClickHouse's own issue tracker - this is a known
-- limitation, not an assumption). So this view resolves the order's
-- details once via a CTE, then inlines each benchmark's logic
-- directly, filtered by that resolved symbol/window - no nested
-- parameterized view calls anywhere in this file.
--
-- The standalone files in queries/benchmarks/ and queries/orders/
-- remain useful on their own (e.g. checking one benchmark in
-- isolation, or reusing the pattern elsewhere) - this view
-- duplicates their logic rather than depending on them, which is a
-- deliberate reliability tradeoff.
--
-- pwp is included as its own column for report labeling, matching
-- interval_vwap exactly under our current no-market-impact
-- assumption (see queries/benchmarks/pwp.sql for why).
--
-- Params:
--   order_id : String
--
-- Returns: orderid, sym, side, orderqty, execution_vwap, plus for
--   each of the 6 benchmarks: <name>_price and <name>_bps
--
-- Example:
--   SELECT * FROM tca.order_scorecard(order_id = 'ORD001');

CREATE OR REPLACE VIEW tca.order_scorecard AS
WITH
    ord AS (
        SELECT orderid, sym, side, orderqty, starttime, endtime, arrivalprice
        FROM tca.orders
        WHERE orderid = {order_id:String}
    ),
    exec_vwap AS (
        SELECT sum(price * qty) / sum(qty) AS execution_vwap
        FROM tca.executions
        WHERE orderid = {order_id:String}
    ),
    bench_interval_vwap AS (
        SELECT sum(t.price * t.qty) / sum(t.qty) AS val
        FROM tca.trades AS t
        CROSS JOIN ord AS o
        WHERE t.sym = o.sym
          AND t.time >= o.starttime
          AND t.time <= o.endtime
    ),
    bench_twap AS (
        SELECT avg((q.bid + q.ask) / 2) AS val
        FROM tca.quotes AS q
        CROSS JOIN ord AS o
        WHERE q.sym = o.sym
          AND q.time >= o.starttime
          AND q.time <= o.endtime
    ),
    bench_full_day_vwap AS (
        SELECT sum(t.price * t.qty) / sum(t.qty) AS val
        FROM tca.trades AS t
        CROSS JOIN ord AS o
        WHERE t.sym = o.sym
          AND toDate(t.time) = toDate(o.starttime)
    ),
    bench_close AS (
        SELECT t.price AS val
        FROM tca.trades AS t
        CROSS JOIN ord AS o
        WHERE t.sym = o.sym
          AND toDate(t.time) = toDate(o.starttime)
        ORDER BY t.time DESC
        LIMIT 1
    )
SELECT
    o.orderid,
    o.sym,
    o.side,
    o.orderqty,
    ev.execution_vwap,

    o.arrivalprice                                       AS arrival_price,
    slippageBps(o.side, ev.execution_vwap, o.arrivalprice) AS arrival_price_bps,

    biv.val                                               AS interval_vwap_price,
    slippageBps(o.side, ev.execution_vwap, biv.val)        AS interval_vwap_bps,

    biv.val                                               AS pwp_price,
    slippageBps(o.side, ev.execution_vwap, biv.val)        AS pwp_bps,

    btw.val                                               AS twap_price,
    slippageBps(o.side, ev.execution_vwap, btw.val)        AS twap_bps,

    bfd.val                                               AS full_day_vwap_price,
    slippageBps(o.side, ev.execution_vwap, bfd.val)        AS full_day_vwap_bps,

    bc.val                                                AS close_price_price,
    slippageBps(o.side, ev.execution_vwap, bc.val)         AS close_price_bps

FROM ord AS o
CROSS JOIN exec_vwap AS ev
CROSS JOIN bench_interval_vwap AS biv
CROSS JOIN bench_twap AS btw
CROSS JOIN bench_full_day_vwap AS bfd
CROSS JOIN bench_close AS bc;
