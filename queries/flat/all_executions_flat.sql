-- all_executions_flat
--
-- Every execution fill, unparameterized, with symbol/date as plain
-- filterable columns and a derived good/bad style label - built for
-- the "trades over time, colored by execution quality" dashboard
-- chart (Superset Mixed Timeseries: this as the scatter series).
--
-- execution_style is derived from the orderid naming convention
-- established in the demo data generation (ORD_<SYM>_<DATE>_GOOD/BAD).
-- If real order IDs don't carry this convention later, this column
-- would instead need to come from a genuine order-quality
-- classification upstream - flagged here so it's not mistaken for a
-- general-purpose rule.
--
-- No params - just:
--   SELECT * FROM tca.all_executions_flat;

CREATE OR REPLACE VIEW tca.all_executions_flat AS
SELECT
    e.orderid                                       AS orderid,
    e.execid                                        AS execid,
    e.sym                                            AS sym,
    e.side                                           AS side,
    e.time                                           AS time,
    toDate(e.time)                                   AS trading_date,
    e.price                                          AS price,
    e.qty                                            AS qty,
    if(e.orderid LIKE '%GOOD%', 'good', 'bad')       AS execution_style
FROM tca.executions AS e;
