#!/bin/bash

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
CREATE TABLE "character" (
  "id" serial PRIMARY KEY,
  "role" int,
  "name" varchar,
  "infobox" varchar,
  "summary" varchar
);
CREATE TABLE "episode" (
  "id" serial PRIMARY KEY,
  "name" varchar,
  "name_cn" varchar,
  "description" varchar,
  "airdate" varchar,
  "disc" int,
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
  "summary" varchar
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
  "tags" varchar,
  "score" float,
  "score_details" varchar,
  "rank" int
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
  "position" int
);
CREATE TABLE "subject-relations" (
  "id" serial PRIMARY KEY,
  "subject_id" int,
  "relation_type" int,
  "related_subject_id" int,
  "order" int
);
EOSQL

if [ -z "$ARCHIVE_PATH" ]; then
  echo "Error: missing ARCHIVE_PATH"
fi

export ARCHIVE_DIR="/tmp/bangumi-archive"
mkdir -p $ARCHIVE_DIR
unzip -q "$ARCHIVE_PATH" -d $ARCHIVE_DIR

for file in "$ARCHIVE_DIR"/*; do
  table_name=$(basename -- "$file" | cut -d. -f1)
  table_header=$(head -n 1 "$file")
  quoted_header=$(echo "$table_header" | awk -F, -v OFS=',' '{for (i=1; i<=NF; i++) $i = "\"" $i "\""}1')
  echo "Copying data from $file to $table_name table..."
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\COPY \"$table_name\"($quoted_header) FROM '$file' WITH NULL AS '' DELIMITER ',' CSV HEADER";
done