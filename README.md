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

Download the current [upstream archive](https://github.com/bangumi/Archive). Build a standalone SQLite database with Python 3. The converter streams the archive and replaces the output only after a successful import.

下载[上游转储](https://github.com/bangumi/Archive)，使用 Python 3 生成可独立查询的 SQLite 文件。转换器逐表读入数据，导入成功后才替换现有文件。

```sh
python3 sqlite/build.py dump.zip bangumi.sqlite
sqlite3 -readonly bangumi.sqlite "SELECT name, name_cn FROM subject WHERE id = 13;"
```

Each JSON Lines file becomes a table. Fields become SQLite columns; nested arrays and objects retain their JSON representation. Original IDs and relationships remain queryable.

每份 JSON Lines 文件对应一张表，嵌套数据保存为 JSON，可按原始 ID 查询和关联。

A maintainer can run **Publish SQLite catalog** in GitHub Actions. The `sqlite` release contains `bangumi.sqlite.gz` and its SHA-256 checksum. Verify the compressed file, then decompress it before opening the database.

维护者可手动运行 **Publish SQLite catalog**，从 `sqlite` 发布页下载压缩数据库和 SHA-256 校验文件。校验后解压即可查询。

The `game_titles` FTS5 trigram index accepts quoted substring searches of at least three Unicode characters and returns the original `id`. Shorter searches can query the source title columns. Building requires SQLite 3.34 or newer with FTS5.

可通过 `game_titles` 的 FTS5 三元组索引，以三个以上字符的片段检索原始条目 ID。构建环境需要支持 FTS5 的 SQLite 3.34 或更新版本。
