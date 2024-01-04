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