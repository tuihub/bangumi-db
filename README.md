# Bangumi Archive Docker Container

This repository provides a way to access the [Bangumi Wiki Dump](https://github.com/bangumi/Archive) through database engine.  
本仓库提供了通过数据库引擎访问[Bangumi Wiki Dump](https://github.com/bangumi/archive)的方法。  

## Postgresql

*The script may break due to the future changes of the dump.*  
*脚本可能会由于未来dump文件的变化而失效。*  

Requires 3GB of disk space.  
Build process may take a long time.  
需要3GB的磁盘空间。  
构建过程可能需要较长时间。  

### Usage

```bash
cd postgresql
# Build and start
docker compose up -d
# Stop
docker compose down
# Force rebuild
docker-compose up --build --force-recreate --no-deps -d
# 如果你网络不佳，可以自定义dump文件的下载地址
ASSET_DOWNLOAD_URL="https://[YOUR_DOWNLOAD_URL]" docker compose up -d
```

## SQLite

Download the [latest dump](https://github.com/bangumi/Archive) to `sqlite/data/archive.zip`.  
下载[最新转储](https://github.com/bangumi/Archive)，保存到 `sqlite/data/archive.zip`。  

Each JSON Lines file becomes a table. Arrays and objects are stored as JSON.  
每份 JSON Lines 文件对应一张表，数组和对象以 JSON 存储。  

### Usage

```bash
cd sqlite
# Build
docker compose run --build --rm sqlite
# Query a subject
sqlite3 -readonly data/bangumi.sqlite "SELECT name, name_cn FROM subject WHERE id = 13;"
# Search game titles with a substring of at least three characters
sqlite3 -readonly data/bangumi.sqlite "SELECT id, title FROM game_titles WHERE game_titles MATCH '\"CLANNAD\"';"
# Build directly with Python 3 (SQLite 3.34+ with FTS5)
python3 build.py data/archive.zip data/bangumi.sqlite
```

After **Publish SQLite catalog** runs in GitHub Actions, verify the checksum from the `sqlite` release and decompress `bangumi.sqlite.gz`.  
GitHub Actions 中的 **Publish SQLite catalog** 运行后，从 `sqlite` 发布页下载校验文件和 `bangumi.sqlite.gz`，校验后解压。  
