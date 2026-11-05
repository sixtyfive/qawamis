#!/usr/bin/env bash
set -euo pipefail

IMAGE="qawamis-web:latest"
ARCHIVE="qawamis-web.tar.gz"

if [[ $# -ne 1 || $1 != *:* ]]; then
    echo "Usage: $0 SERVER:REMOTE_DIR" >&2
    exit 1
fi

SERVER=${1%%:*}
REMOTE_DIR=${1#*:}

if [[ -z $SERVER || -z $REMOTE_DIR ]]; then
    echo "Error: SERVER and REMOTE_DIR must not be empty" >&2
    exit 1
fi

docker save "$IMAGE" | gzip > "$ARCHIVE"
scp "$ARCHIVE" "$SERVER:$REMOTE_DIR/"

ssh "$SERVER" "cd $REMOTE_DIR && \
    gzip -dc $ARCHIVE | docker load && \
    docker compose up -d && \
    rm $ARCHIVE"

rm "$ARCHIVE"
