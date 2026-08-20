-- participation_rate(order_id)
--
-- What fraction of total market volume the order represented over
-- its own execution window - a standard "how aggressive was this
-- order relative to available liquidity" diagnostic.
--
-- Self-contained (duplicates order lookup + volume-sum logic rather
-- than composing order_info + interval_volume) - see order_scorecard.sql
-- for why cross-parameterized-view composition is avoided throughout
-- this project.
--
-- Params:
--   order_id : String
--
-- Returns: orderid, sym, orderqty, market_volume, participation_pct
--
-- Example:
--   SELECT * FROM tca.participation_rate(order_id = 'ORD001');

CREATE OR REPLACE VIEW tca.participation_rate AS
WITH
    ord AS (
        SELECT orderid, sym, orderqty, starttime, endtime
        FROM tca.orders
        WHERE orderid = {order_id:String}
    ),
    mkt AS (
        SELECT sum(t.qty) AS market_volume
        FROM tca.trades AS t
        CROSS JOIN ord AS o
        WHERE t.sym = o.sym
          AND t.time >= o.starttime
          AND t.time <= o.endtime
    )
SELECT
    o.orderid,
    o.sym,
    o.orderqty,
    mkt.market_volume,
    o.orderqty / mkt.market_volume * 100 AS participation_pct
FROM ord AS o
CROSS JOIN mkt;
