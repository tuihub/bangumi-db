# Bangumi Archive Databases

Query [Bangumi Wiki Dump](https://github.com/bangumi/Archive) data with PostgreSQL or SQLite.  
通过 PostgreSQL 或 SQLite 查询 [Bangumi Wiki Dump](https://github.com/bangumi/Archive) 数据。  

PostgreSQL and SQLite share the table definitions in [schema/bangumi.sql](schema/bangumi.sql).  
PostgreSQL 和 SQLite 共用 [schema/bangumi.sql](schema/bangumi.sql) 中的表定义。  

## PostgreSQL

*Changes to the dump format may break the import script.*  
*转储格式变化可能导致导入脚本失效。*  

Requires 3 GB of disk space.  
The build may take a long time.  
构建需要 3 GB 磁盘空间。  
构建可能耗时较长。  

### Usage

```bash
cd postgresql
# Build and start
docker compose up -d
# Stop
docker compose down
# Force rebuild
docker-compose up --build --force-recreate --no-deps -d
# 自定义转储下载地址
ASSET_DOWNLOAD_URL="https://[YOUR_DOWNLOAD_URL]" docker compose up -d
```

## SQLite

*Changes to the dump format may break the import script.*  
*转储格式变化可能导致导入脚本失效。*  

Requires 2 GB of disk space.  
The build may take a long time.  
构建需要 2 GB 磁盘空间。  
构建可能耗时较长。  

### Usage

Prebuilt SQLite databases are available on the [release page](https://github.com/tuihub/bangumi-db/releases/tag/sqlite). Each ZIP contains `bangumi.sqlite`, has the same filename as its source dump, and comes with a `.sha256` checksum file.  
预构建的 SQLite 数据库可在 [发布页](https://github.com/tuihub/bangumi-db/releases/tag/sqlite) 下载。每个 ZIP 内含 `bangumi.sqlite`，与对应的上游转储同名，并附有 `.sha256` 校验文件。  

```bash
# Replace with a filename from the release page
archive="dump-YYYY-MM-DD.HHMMSSZ.zip"
curl -fLO "https://github.com/tuihub/bangumi-db/releases/download/sqlite/$archive"
unzip "$archive"
```

### Build

```bash
cd sqlite
# Build
docker compose run --build --rm sqlite
# 自定义转储下载地址
ASSET_DOWNLOAD_URL="https://[YOUR_DOWNLOAD_URL]" docker compose run --build --rm sqlite
```

Use Python 3 to build the database directly from a downloaded dump. Python's `sqlite3` module must use SQLite 3.34 or later with FTS5 enabled. Check SQLite support by running `python3 build.py --check` from `sqlite/`.  
用 Python 3 直接从下载的转储文件建库。`sqlite3` 模块所用的 SQLite 需为 3.34 或更高版本，且已启用 FTS5。在 `sqlite/` 下运行 `python3 build.py --check` 可检查 SQLite 支持情况。  

```bash
cd sqlite
mkdir -p data
python3 build.py /path/to/dump.zip data/bangumi.sqlite
```
