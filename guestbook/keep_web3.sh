#!/bin/bash
# web 컨테이너를 항상 3개로 유지하는 감시 스크립트

cd "$(dirname "$0")" || exit 1

TARGET=3
INTERVAL=10

while true; do
  RUNNING=$(docker compose ps web | grep "Up" | wc -l)

  if [ "$RUNNING" -lt "$TARGET" ]; then
    echo "[$(date +%H:%M:%S)] web ${RUNNING}개 → ${TARGET}개로 복구"
    docker compose up -d --scale web="$TARGET"
  fi

  sleep "$INTERVAL"
done
