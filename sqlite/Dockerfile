FROM python:3.12-slim-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl jq \
    && rm -rf /var/lib/apt/lists/*

COPY schema/bangumi.sql /app/schema/
COPY sqlite/build.py sqlite/initdb.sh /app/sqlite/
RUN sed -i 's/\r$//' /app/sqlite/initdb.sh

ENTRYPOINT ["sh", "/app/sqlite/initdb.sh"]
