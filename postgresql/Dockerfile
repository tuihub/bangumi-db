FROM postgres:16-alpine
SHELL ["/bin/bash", "-c"]

ARG ARCHIVE_PATH="/archive.zip"
ARG RELEASE_BASE_URL="https://api.github.com/repos/bangumi/Archive/releases/tags/archive"
ARG TEMP_DIR="/tmp/archive"

RUN echo "Downloading Archive"

RUN apk add --no-cache unzip zip curl jq miller

# Download the Archive file
RUN if [ -n "$ASSET_DOWNLOAD_URL" ]; then \
      wget -O "$ARCHIVE_PATH" "$ASSET_DOWNLOAD_URL"; \
    else \
      export NEWEST_ASSET_DOWNLOAD_URL=$(curl -s "$RELEASE_BASE_URL" | jq -r '.assets | max_by(.created_at) | .browser_download_url'); \
      wget -O "$ARCHIVE_PATH" "$NEWEST_ASSET_DOWNLOAD_URL"; \
    fi;
# Convert the jsonlines file to csv
RUN unzip -q "$ARCHIVE_PATH" -d $TEMP_DIR
RUN for file in $TEMP_DIR/*.jsonlines; do \
        mlr --no-auto-flatten --l2c cat $file > "${file%.*}.csv"; \
    done;
RUN rm $ARCHIVE_PATH
RUN zip -q -j "$ARCHIVE_PATH" $TEMP_DIR/*.csv
RUN rm -r $TEMP_DIR

RUN echo "Building Image"

COPY initdb.sh /docker-entrypoint-initdb.d/

ENV ARCHIVE_PATH $ARCHIVE_PATH
ENV POSTGRES_DB bangumi
ENV POSTGRES_USER bangumi
ENV POSTGRES_PASSWORD bangumi
ENV ON_ERROR_STOP 1

EXPOSE 5432
