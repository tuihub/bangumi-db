CREATE TABLE "character" (
  "id" INTEGER PRIMARY KEY,
  "role" int,
  "name" varchar,
  "infobox" varchar,
  "summary" varchar,
  "comments" int,
  "collects" int
);
CREATE TABLE "episode" (
  "id" INTEGER PRIMARY KEY,
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
  "id" INTEGER PRIMARY KEY,
  "name" varchar,
  "type" int,
  "career" varchar,
  "infobox" varchar,
  "summary" varchar,
  "comments" int,
  "collects" int
);
CREATE TABLE "person-characters" (
  "id" INTEGER PRIMARY KEY,
  "person_id" int,
  "subject_id" int,
  "character_id" int,
  "summary" varchar,
  "type" int
);
CREATE TABLE "subject" (
  "id" INTEGER PRIMARY KEY,
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
  "id" INTEGER PRIMARY KEY,
  "character_id" int,
  "subject_id" int,
  "type" int,
  "order" int
);
CREATE TABLE "subject-persons" (
  "id" INTEGER PRIMARY KEY,
  "person_id" int,
  "subject_id" int,
  "position" int,
  "appear_eps" varchar
);
CREATE TABLE "subject-relations" (
  "id" INTEGER PRIMARY KEY,
  "subject_id" int,
  "relation_type" int,
  "related_subject_id" int,
  "order" int
);
CREATE TABLE "person-relations" (
  "id" INTEGER PRIMARY KEY,
  "person_type" varchar,
  "person_id" int,
  "related_person_id" int,
  "relation_type" int,
  "spoiler" boolean,
  "ended" boolean
);
