-- market_price_trend
--
-- Time-bucketed (1-minute) average trade price per symbol - the
-- backdrop context line for the "trades over time, colored by
-- execution quality" dashboard chart (Superset Mixed Timeseries:
-- this as the line series, all_executions_flat as the scatter series
-- on top of it).
--
-- No params - just:
--   SELECT * FROM tca.market_price_trend;

CREATE OR REPLACE VIEW tca.market_price_trend AS
SELECT
    sym                        AS sym,
    toStartOfMinute(time)      AS time_bucket,
    toDate(time)                AS trading_date,
    avg(price)                  AS avg_price,
    sum(qty)                    AS volume
FROM tca.trades
GROUP BY sym, time_bucket, trading_date
ORDER BY sym, time_bucket;
