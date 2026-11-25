#!/bin/bash
set -euo pipefail

# Use PostgreSQL sequences to generate IDs omitted from the dump.
sed 's/"id" INTEGER PRIMARY KEY/"id" SERIAL PRIMARY KEY/' /schema/bangumi.sql |
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"

if [ -z "$ARCHIVE_PATH" ]; then
  echo "ARCHIVE_PATH is empty. Set it to the dump archive path."
  exit 1
fi

export ARCHIVE_DIR="/tmp/bangumi-archive"
mkdir -p $ARCHIVE_DIR
unzip -q "$ARCHIVE_PATH" -d $ARCHIVE_DIR

quote_ident() {
  local value="$1"
  printf '"%s"' "${value//\"/\"\"}"
}

ensure_table() {
  local table_name="$1"
  local table_header="$2"

  if ! psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$table_name'" | grep -q 1; then
    local columns_sql=""
    IFS=',' read -ra headers <<< "$table_header"
    for column in "${headers[@]}"; do
      column="${column%$'\r'}"
      if [ -n "$columns_sql" ]; then
        columns_sql+=", "
      fi
      columns_sql+="$(quote_ident "$column") varchar"
    done
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "CREATE TABLE $(quote_ident "$table_name") ($columns_sql);"
    return
  fi

  IFS=',' read -ra headers <<< "$table_header"
  for column in "${headers[@]}"; do
    column="${column%$'\r'}"
    if ! psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '$table_name' AND column_name = '$column'" | grep -q 1; then
      psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ALTER TABLE $(quote_ident "$table_name") ADD COLUMN $(quote_ident "$column") varchar;"
    fi
  done
}

for file in "$ARCHIVE_DIR"/*; do
  table_name=$(basename -- "$file" | cut -d. -f1)
  table_header=$(head -n 1 "$file")
  quoted_header=$(echo "$table_header" | awk -F, -v OFS=',' '{for (i=1; i<=NF; i++) $i = "\"" $i "\""}1')
  echo "Importing $file into $table_name..."
  ensure_table "$table_name" "$table_header"
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\COPY \"$table_name\"($quoted_header) FROM '$file' WITH (DELIMITER ',', ON_ERROR ignore, FORMAT CSV, HEADER)";
done
