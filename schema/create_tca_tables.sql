-- Recreate TCA tables with explicit UTC timezone on all timestamp columns.
-- Without this, DateTime64 columns are interpreted using the ClickHouse
-- server's local timezone (e.g. Asia/Singapore, UTC+8), silently shifting
-- displayed times away from what was actually simulated (e.g. 09:30 shows
-- as 17:30). The underlying kdb timestamps are timezone-naive, so UTC is
-- used here by convention for a consistent, portable interpretation.

DROP TABLE IF EXISTS tca.trades;
DROP TABLE IF EXISTS tca.quotes;
DROP TABLE IF EXISTS tca.orders;
DROP TABLE IF EXISTS tca.executions;

CREATE DATABASE IF NOT EXISTS tca;

CREATE TABLE tca.trades
(
    sym    String,
    time   DateTime64(9, 'UTC'),
    price  Float64,
    qty    Int64
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(time)
ORDER BY (sym, time);

CREATE TABLE tca.quotes
(
    sym      String,
    time     DateTime64(9, 'UTC'),
    bid      Float64,
    ask      Float64,
    bidsize  Int64,
    asksize  Int64
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(time)
ORDER BY (sym, time);

CREATE TABLE tca.orders
(
    orderid       String,
    sym           String,
    side          String,
    orderqty      Int64,
    starttime     DateTime64(9, 'UTC'),
    endtime       DateTime64(9, 'UTC'),
    arrivalprice  Float64
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(starttime)
ORDER BY (sym, starttime);

CREATE TABLE tca.executions
(
    orderid  String,
    execid   Int64,
    sym      String,
    side     String,
    time     DateTime64(9, 'UTC'),
    price    Float64,
    qty      Int64
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(time)
ORDER BY (sym, time);
