-- order_info(order_id)
--
-- Basic lookup of a parent order's details - symbol, side, quantity,
-- execution window, and arrival price. Every downstream cost/slippage
-- calculation needs these fields, so this centralizes the lookup
-- rather than repeating it in every benchmark comparison query.
--
-- Params:
--   order_id : String
--
-- Returns: orderid, sym, side, orderqty, starttime, endtime, arrivalprice
--
-- Example:
--   SELECT * FROM tca.order_info(order_id = 'ORD001');

CREATE OR REPLACE VIEW tca.order_info AS
SELECT
    orderid,
    sym,
    side,
    orderqty,
    starttime,
    endtime,
    arrivalprice
FROM tca.orders
WHERE orderid = {order_id:String};
