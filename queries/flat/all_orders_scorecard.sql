-- all_orders_scorecard
--
-- The Superset/BI-tool-friendly version of orders_report: SAME logic,
-- but with NO parameters. Returns every order's full 6-benchmark
-- scorecard as plain rows, with symbol/side/date as ordinary output
-- columns - so dashboard tools can filter/slice via their own normal
-- WHERE-clause-generating UI widgets, rather than needing to inject
-- ClickHouse parameterized-view arguments (which BI tools generally
-- cannot do).
--
-- This is deliberately a separate, purpose-built layer rather than a
-- replacement for orders_report/order_scorecard - those remain the
-- reusable, parameterized "engine" for any other consumer (an API,
-- another tool, direct SQL access). This view exists specifically to
-- unblock plain SELECT/WHERE/GROUP BY dashboard tooling.
--
-- trading_date is included explicitly as a plain Date column, since
-- BI tools generally need a proper temporal column to drive
-- time-series charts and native date-range filter widgets.
--
-- No params - just:
--   SELECT * FROM tca.all_orders_scorecard;

CREATE OR REPLACE VIEW tca.all_orders_scorecard AS
WITH
    ord AS (
        SELECT orderid, sym, side, orderqty, starttime, endtime, arrivalprice
        FROM tca.orders
    ),
    exec_vwap AS (
        SELECT e.orderid, sum(e.price * e.qty) / sum(e.qty) AS execution_vwap
        FROM tca.executions AS e
        INNER JOIN ord AS o ON o.orderid = e.orderid
        GROUP BY e.orderid
    ),
    bench_interval_vwap AS (
        SELECT o.orderid, sum(t.price * t.qty) / sum(t.qty) AS val
        FROM ord AS o
        INNER JOIN tca.trades AS t
            ON t.sym = o.sym AND t.time >= o.starttime AND t.time <= o.endtime
        GROUP BY o.orderid
    ),
    bench_twap AS (
        SELECT o.orderid, avg((q.bid + q.ask) / 2) AS val
        FROM ord AS o
        INNER JOIN tca.quotes AS q
            ON q.sym = o.sym AND q.time >= o.starttime AND q.time <= o.endtime
        GROUP BY o.orderid
    ),
    bench_full_day_vwap AS (
        SELECT o.orderid, sum(t.price * t.qty) / sum(t.qty) AS val
        FROM ord AS o
        INNER JOIN tca.trades AS t
            ON t.sym = o.sym AND toDate(t.time) = toDate(o.starttime)
        GROUP BY o.orderid
    ),
    bench_close AS (
        SELECT o.orderid, argMax(t.price, t.time) AS val
        FROM ord AS o
        INNER JOIN tca.trades AS t
            ON t.sym = o.sym AND toDate(t.time) = toDate(o.starttime)
        GROUP BY o.orderid
    )
SELECT
    o.orderid                                             AS orderid,
    o.sym                                                 AS sym,
    o.side                                                AS side,
    o.orderqty                                            AS orderqty,
    toDate(o.starttime)                                   AS trading_date,
    ev.execution_vwap                                     AS execution_vwap,

    o.arrivalprice                                        AS arrival_price,
    slippageBps(o.side, ev.execution_vwap, o.arrivalprice) AS arrival_price_bps,

    biv.val                                                AS interval_vwap_price,
    slippageBps(o.side, ev.execution_vwap, biv.val)        AS interval_vwap_bps,

    biv.val                                                AS pwp_price,
    slippageBps(o.side, ev.execution_vwap, biv.val)        AS pwp_bps,

    btw.val                                                AS twap_price,
    slippageBps(o.side, ev.execution_vwap, btw.val)        AS twap_bps,

    bfd.val                                                AS full_day_vwap_price,
    slippageBps(o.side, ev.execution_vwap, bfd.val)        AS full_day_vwap_bps,

    bc.val                                                 AS close_price_price,
    slippageBps(o.side, ev.execution_vwap, bc.val)         AS close_price_bps

FROM ord AS o
INNER JOIN exec_vwap AS ev ON ev.orderid = o.orderid
INNER JOIN bench_interval_vwap AS biv ON biv.orderid = o.orderid
INNER JOIN bench_twap AS btw ON btw.orderid = o.orderid
INNER JOIN bench_full_day_vwap AS bfd ON bfd.orderid = o.orderid
INNER JOIN bench_close AS bc ON bc.orderid = o.orderid
ORDER BY o.sym, o.starttime, o.orderid;
