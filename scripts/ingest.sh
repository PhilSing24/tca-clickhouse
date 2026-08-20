#!/bin/bash
# ingest.sh - load trades/quotes/orders/executions Parquet files into ClickHouse
#
# Usage:
#   ./ingest.sh [data_dir]
#
# data_dir defaults to ~/kdbx-modules/data if not given.
# Expects four files in data_dir: trades.parquet, quotes.parquet,
# orders.parquet, executions.parquet
#
# Truncates each table before loading, so re-running this script with a
# fresh set of Parquet files replaces the previous dataset rather than
# appending duplicate rows on top of it.

set -e

CLICKHOUSE_BIN="$HOME/clickhouse"
CLICKHOUSE_HOST="::1"
DATABASE="tca"
TABLES=(trades quotes orders executions)

DATA_DIR="${1:-$HOME/kdbx-modules/data}"

echo "Data directory: $DATA_DIR"
echo "Database: $DATABASE"
echo ""

# Check all four files exist before touching anything
for t in "${TABLES[@]}"; do
  f="$DATA_DIR/$t.parquet"
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing file $f"
    exit 1
  fi
done

for t in "${TABLES[@]}"; do
  f="$DATA_DIR/$t.parquet"
  echo "--- $t ---"

  echo "Truncating $DATABASE.$t..."
  "$CLICKHOUSE_BIN" client --host "$CLICKHOUSE_HOST" \
    --query "TRUNCATE TABLE $DATABASE.$t"

  echo "Loading $f..."
  "$CLICKHOUSE_BIN" client --host "$CLICKHOUSE_HOST" \
    --query "INSERT INTO $DATABASE.$t FORMAT Parquet" < "$f"

  echo "Done."
  echo ""
done

echo "=== Row counts ==="
"$CLICKHOUSE_BIN" client --host "$CLICKHOUSE_HOST" --query "
SELECT 'trades' AS t, count() FROM $DATABASE.trades
UNION ALL
SELECT 'quotes', count() FROM $DATABASE.quotes
UNION ALL
SELECT 'orders', count() FROM $DATABASE.orders
UNION ALL
SELECT 'executions', count() FROM $DATABASE.executions
"
