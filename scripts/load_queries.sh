#!/bin/bash
# load_queries.sh - create/refresh all views in queries/
#
# Usage:
#   ./load_queries.sh
#
# Runs every .sql file under queries/helpers/, queries/benchmarks/,
# and queries/reports/ (in that order - helpers are small reusable
# pieces some benchmarks/reports may build on; reports may build on
# benchmarks) against ClickHouse.

set -e

CLICKHOUSE_BIN="$HOME/clickhouse"
CLICKHOUSE_HOST="::1"
QUERIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/queries"

for layer in helpers benchmarks reports; do
  dir="$QUERIES_DIR/$layer"
  if [[ -d "$dir" ]]; then
    for f in "$dir"/*.sql; do
      [[ -e "$f" ]] || continue
      echo "Loading $layer/$(basename "$f")..."
      "$CLICKHOUSE_BIN" client --host "$CLICKHOUSE_HOST" --queries-file "$f"
    done
  fi
done

echo ""
echo "Done. Views in tca database:"
"$CLICKHOUSE_BIN" client --host "$CLICKHOUSE_HOST" --query "SHOW TABLES FROM tca"
