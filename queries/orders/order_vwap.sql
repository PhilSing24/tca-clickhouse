-- order_vwap(order_id)
--
-- Volume-weighted average price of an order's OWN fills - what you
-- actually paid on average. This is the "execution price" side of
-- every benchmark comparison (paired against arrival_price, VWAP,
-- TWAP, etc. from queries/benchmarks/).
--
-- Distinct from any market-side benchmark: this reads from
-- tca.executions (your fills), not tca.trades (the market).
--
-- Params:
--   order_id : String
--
-- Returns: orderid, sym, side, execution_vwap, total_qty, execution_count
--
-- Example:
--   SELECT * FROM tca.order_vwap(order_id = 'ORD001');

CREATE OR REPLACE VIEW tca.order_vwap AS
SELECT
    orderid,
    sym,
    side,
    sum(price * qty) / sum(qty) AS execution_vwap,
    sum(qty) AS total_qty,
    count() AS execution_count
FROM tca.executions
WHERE orderid = {order_id:String}
GROUP BY orderid, sym, side;
