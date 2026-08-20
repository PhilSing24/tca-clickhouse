# tca-clickhouse

ClickHouse schema and ingestion tooling for Transaction Cost Analysis (TCA) data.

## About

This project is independent of how the underlying data was generated. It expects four Parquet files — `trades`, `quotes`, `orders`, `executions` — matching the schema defined in `schema/create_tca_tables.sql`, and loads them into ClickHouse for querying.

The Parquet files can come from any source that produces this schema. One such source is [kdbx-modules](https://github.com/PhilSing24/kdbx-simtick) (`di.simtick` + `di.simorder`), which generates realistic simulated market data and order executions — but this project has no dependency on it.

## Schema

| Table | Description |
|-------|-------------|
| `trades` | Market prints — what everyone traded |
| `quotes` | Market bid/ask — what was quotable |
| `orders` | Parent order intent — what you meant to do |
| `executions` | Actual fills — what you actually did |

All timestamp columns use `DateTime64(9, 'UTC')` — explicit UTC to avoid values being silently reinterpreted under the ClickHouse server's local timezone.

Tables use `MergeTree`, partitioned by `toYYYYMM(time)` and ordered by `(sym, time)`, so symbol/time-range queries and `ASOF JOIN`s between tables are efficient.

## Setup

1. Install and start ClickHouse (see [ClickHouse docs](https://clickhouse.com/docs/install)):
```bash
curl https://clickhouse.com/ | sh
./clickhouse server
```

2. In a separate terminal, create the database and tables:
```bash
./clickhouse client --host ::1 --queries-file schema/create_tca_tables.sql
```

## Ingesting data

```bash
./scripts/ingest.sh [data_dir]
```

- `data_dir` defaults to `~/kdbx-modules/data` if not given
- Expects `trades.parquet`, `quotes.parquet`, `orders.parquet`, `executions.parquet` in that directory
- **Truncates each table before loading**, so re-running with a new dataset replaces the previous one rather than appending duplicate rows

Example, pointing at a different data source:
```bash
./scripts/ingest.sh /path/to/other/parquet/files
```

## Project Structure

```
tca-clickhouse/
├── schema/
│   └── create_tca_tables.sql   # Database + table definitions
├── scripts/
│   └── ingest.sh                # Reusable Parquet -> ClickHouse loader
└── README.md
```

## License

MIT
