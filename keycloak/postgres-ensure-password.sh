#!/bin/bash
set -euo pipefail

term_handler() {
  if [[ -n "${pg_pid:-}" ]] && kill -0 "$pg_pid" 2>/dev/null; then
    kill "$pg_pid"
    wait "$pg_pid"
  fi
}

trap term_handler TERM INT

/usr/local/bin/docker-entrypoint.sh postgres &
pg_pid=$!

until pg_isready -h 127.0.0.1 -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; do
  sleep 2
done

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
  --set=db_user="$POSTGRES_USER" \
  --set=db_password="$POSTGRES_PASSWORD" <<'SQL'
ALTER USER :"db_user" WITH PASSWORD :'db_password';
SQL

wait "$pg_pid"
