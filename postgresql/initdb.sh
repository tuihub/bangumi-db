#!/bin/bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
CREATE TABLE "character" (
  "id" serial PRIMARY KEY,
  "role" int,
  "name" varchar,
  "infobox" varchar,
  "summary" varchar,
  "comments" int,
  "collects" int
);
CREATE TABLE "episode" (
  "id" serial PRIMARY KEY,
  "name" varchar,
  "name_cn" varchar,
  "description" varchar,
  "airdate" varchar,
  "disc" int,
  "duration" text,
  "subject_id" int,
  "sort" float,
  "type" int
);
CREATE TABLE "person" (
  "id" serial PRIMARY KEY,
  "name" varchar,
  "type" int,
  "career" varchar,
  "infobox" varchar,
  "summary" varchar,
  "comments" int,
  "collects" int
);
CREATE TABLE "person-characters" (
  "id" serial PRIMARY KEY,
  "person_id" int,
  "subject_id" int,
  "character_id" int,
  "summary" varchar
);
CREATE TABLE "subject" (
  "id" serial PRIMARY KEY,
  "type" int,
  "name" varchar,
  "name_cn" varchar,
  "infobox" varchar,
  "platform" int,
  "summary" varchar,
  "nsfw" boolean,
  "date" varchar,
  "tags" varchar,
  "score" float,
  "score_details" varchar,
  "rank" int,
  "favorite" varchar,
  "series" boolean,
  "meta_tags" varchar
);
CREATE TABLE "subject-characters" (
  "id" serial PRIMARY KEY,
  "character_id" int,
  "subject_id" int,
  "type" int,
  "order" int
);
CREATE TABLE "subject-persons" (
  "id" serial PRIMARY KEY,
  "person_id" int,
  "subject_id" int,
  "position" int,
  "appear_eps" varchar
);
CREATE TABLE "subject-relations" (
  "id" serial PRIMARY KEY,
  "subject_id" int,
  "relation_type" int,
  "related_subject_id" int,
  "order" int
);
CREATE TABLE "person-relations" (
  "id" serial PRIMARY KEY,
  "person_type" varchar,
  "person_id" int,
  "related_person_id" int,
  "relation_type" int,
  "spoiler" boolean,
  "ended" boolean
);
EOSQL

if [ -z "$ARCHIVE_PATH" ]; then
  echo "Error: missing ARCHIVE_PATH"
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
  echo "Copying data from $file to $table_name table..."
  ensure_table "$table_name" "$table_header"
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\COPY \"$table_name\"($quoted_header) FROM '$file' WITH (DELIMITER ',', ON_ERROR ignore, FORMAT CSV, HEADER)";
done
