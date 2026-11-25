"""Build a standalone SQLite database from a Bangumi Archive ZIP."""
import argparse
import hashlib
import json
import os
import tempfile
import zipfile
from contextlib import closing
from pathlib import Path

try:
    import sqlite3
except ImportError as error:
    raise SystemExit(f"The sqlite3 module is unavailable ({error}).") from None


SCHEMA_PATH = Path(__file__).resolve().parent.parent / "schema" / "bangumi.sql"
CREATE_GAME_TITLES_TABLE = (
    "CREATE VIRTUAL TABLE game_titles "
    "USING fts5(id UNINDEXED, title, tokenize='trigram')"
)


def check_environment():
    try:
        with closing(sqlite3.connect(":memory:")) as db:
            db.execute(CREATE_GAME_TITLES_TABLE)
    except sqlite3.Error as error:
        raise SystemExit(
            f"SQLite {sqlite3.sqlite_version} cannot create an FTS5 trigram index ({error}). "
            "Use Python with SQLite 3.34 or later and FTS5 enabled."
        ) from None


def ident(name):
    return '"' + name.replace('"', '""') + '"'


def value(data):
    if isinstance(data, (dict, list)):
        return json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    return data


def load_table(db, table, stream):
    columns = {}
    table_columns = {column[1] for column in db.execute(f"PRAGMA table_info({ident(table)})")}
    if not table_columns:
        db.execute(f"CREATE TABLE {ident(table)} (_row INTEGER PRIMARY KEY)")
    for line in stream:
        data = json.loads(line)
        if not isinstance(data, dict):
            raise ValueError(f"Expected a JSON object in {table}.")
        new = data.keys() - columns.keys()
        if new or not columns:
            for key in data:
                if key not in columns:
                    columns[key] = None
                    if key not in table_columns:
                        db.execute(f"ALTER TABLE {ident(table)} ADD COLUMN {ident(key)}")
            sql = (f"INSERT INTO {ident(table)} ({','.join(map(ident, columns))}) "
                   f"VALUES ({','.join('?' for key in columns)})")
        db.execute(sql, tuple(value(data.get(key)) for key in columns))
    for key in ("subject_id", "person_id", "character_id", "related_subject_id"):
        if key in columns:
            db.execute(f"CREATE INDEX {ident(table + '_' + key)} ON {ident(table)} ({ident(key)})")


def convert(archive, output):
    check_environment()
    with tempfile.TemporaryDirectory(dir=output.parent) as temp:
        stage = Path(temp) / "bangumi.sqlite"
        with zipfile.ZipFile(archive) as source, closing(sqlite3.connect(stage)) as db, db:
            db.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
            db.execute("BEGIN")
            digest = hashlib.sha256()
            with archive.open("rb") as data:
                for block in iter(lambda: data.read(1024 * 1024), b""):
                    digest.update(block)
            db.execute("CREATE TABLE dump_info (name TEXT PRIMARY KEY, content TEXT NOT NULL)")
            db.executemany("INSERT INTO dump_info VALUES (?,?)", [
                ("source", "https://github.com/bangumi/Archive"),
                ("sha256", digest.hexdigest()),
            ])
            tables = set()
            for member in source.infolist():
                path = Path(member.filename)
                if path.suffix == ".jsonlines":
                    print(path.stem, flush=True)
                    with source.open(member) as stream:
                        load_table(db, path.stem, stream)
                    tables.add(path.stem)
            if "subject" not in tables:
                raise ValueError("Missing subject.jsonlines in the archive.")
            db.execute(CREATE_GAME_TITLES_TABLE)
            db.execute("INSERT INTO game_titles SELECT id, name FROM subject WHERE type=4 UNION ALL SELECT id, name_cn FROM subject WHERE type=4 AND name_cn<>''")
        os.replace(stage, output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="check support for FTS5 trigram indexes and exit")
    parser.add_argument("archive", type=Path, nargs="?")
    parser.add_argument("output", type=Path, nargs="?")
    args = parser.parse_args()
    if args.check:
        check_environment()
        print(f"SQLite {sqlite3.sqlite_version} supports FTS5 trigram indexes.")
    elif args.archive is None or args.output is None:
        parser.error("archive and output are required")
    else:
        convert(args.archive, args.output)
