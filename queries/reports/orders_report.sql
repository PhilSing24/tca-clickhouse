-- orders_report(symbol, start_date, end_date)
--
-- The multi-order version of order_scorecard: one row per order whose
-- starttime falls in [start_date, end_date] for the given symbol,
-- each with execution VWAP compared against all 6 benchmarks (price
-- + bps) - a real report you can sort, average, or group by, instead
-- of calling order_scorecard once per order_id by hand.
--
-- DESIGN NOTE: unlike order_scorecard (which resolves ONE order into
-- a single-row CTE), this may match MANY orders, each with its own
-- symbol/window. So benchmark calculations use JOINs with inequality
-- conditions (t.time >= o.starttime AND t.time <= o.endtime),
-- grouped per order - a standard "range join" pattern, not
-- correlated subqueries or cross-parameterized-view composition
-- (both of which have known reliability issues - see
-- order_scorecard.sql for the composition discussion).
--
-- Params:
--   symbol     : String
--   start_date : DateTime64(9, 'UTC')
--   end_date   : DateTime64(9, 'UTC')
--
-- Returns: one row per order - orderid, sym, side, orderqty,
--   execution_vwap, plus <name>_price and <name>_bps for each of
--   the 6 benchmarks
--
-- Example:
--   SELECT * FROM tca.orders_report(
--     symbol = 'NVDA',
--     start_date = '2026-01-20 00:00:00.000000000',
--     end_date   = '2026-01-21 00:00:00.000000000'
--   );

CREATE OR REPLACE VIEW tca.orders_report AS
WITH
    ord AS (
        SELECT orderid, sym, side, orderqty, starttime, endtime, arrivalprice
        FROM tca.orders
        WHERE sym = {symbol:String}
          AND starttime >= {start_date:DateTime64(9, 'UTC')}
          AND starttime <= {end_date:DateTime64(9, 'UTC')}
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
    o.orderid AS orderid,
    o.sym,
    o.side,
    o.orderqty,
    ev.execution_vwap,

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
ORDER BY o.orderid;
