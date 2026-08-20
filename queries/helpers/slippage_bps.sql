-- slippageBps(side, execution_price, benchmark_price)
--
-- The generic TCA cost formula: signed slippage in basis points.
-- Positive = cost (execution was worse than the benchmark).
-- Negative = savings (execution beat the benchmark).
--
-- Sign convention: for BUY orders, paying MORE than the benchmark is
-- a cost (positive). For SELL orders, receiving LESS than the
-- benchmark is a cost (positive) - the sign flips so "positive always
-- means cost" regardless of order side, which is what makes results
-- comparable/aggregable across a mix of buy and sell orders.
--
-- This is a genuine ClickHouse SQL function (CREATE FUNCTION), not a
-- view - it's a pure scalar formula, no table access, so it can be
-- called directly inside any SELECT (see queries/scorecards/).
--
-- Params:
--   side             : String  ('BUY' or 'SELL')
--   execution_price  : Float64
--   benchmark_price  : Float64
--
-- Returns: Float64 (basis points)
--
-- Example:
--   SELECT slippageBps('BUY', 180.32, 181.125);
--   -- negative: execution price below benchmark = savings for a BUY

CREATE FUNCTION IF NOT EXISTS slippageBps AS (side, execution_price, benchmark_price) ->
    multiIf(side = 'BUY', 1, side = 'SELL', -1, NULL)
    * (execution_price - benchmark_price) / benchmark_price * 10000;
