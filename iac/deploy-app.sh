#!/usr/bin/env bash
# Goバイナリをローカルでビルドして bare VM に配備する。
# 使い方: ./deploy-app.sh <VMのIP or ホスト名> [ブランチ(既定: develop)]
#
# cgo(annoyindexのC++バインディング)があるため、linux/amd64 + glibc の
# コンテナ内でビルドする(alpine/muslはUbuntu実行不可なので使わない)。
set -euo pipefail

HOST="${1:?使い方: ./deploy-app.sh <VMのIP> [ブランチ]}"
BRANCH="${2:-develop}"
OUT_DIR="$(mktemp -d)"
trap 'rm -rf "$OUT_DIR"' EXIT

echo "=== 1. linux/amd64 バイナリをビルド(golang:1.18 / glibc)==="
docker run --rm --platform linux/amd64 \
  -v "$OUT_DIR":/out \
  -v news-app-go-mod-cache:/go/pkg/mod \
  golang:1.18 bash -c "
    set -e
    git clone --depth 1 -b '$BRANCH' https://github.com/ponyo877/news-app-backend-refactor.git /src
    cd /src
    go build -o /out/news-app api/main.go
  "
ls -lh "$OUT_DIR/news-app"

echo "=== 2. 転送と再起動 ==="
scp "$OUT_DIR/news-app" "$HOST":/tmp/news-app
ssh "$HOST" "sudo install -m 755 -o newsapp -g newsapp /tmp/news-app /opt/news-app/news-app && rm /tmp/news-app && sudo systemctl restart news-app && sleep 2 && systemctl is-active news-app && curl -fsS -m 10 http://127.0.0.1:8000/health"

echo "=== 完了 ==="
