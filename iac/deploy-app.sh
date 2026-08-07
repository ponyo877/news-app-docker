#!/usr/bin/env bash
# Goバイナリをローカルでクロスコンパイルして bare VM に配備する。
# 使い方: ./deploy-app.sh <VMのIP or ホスト名> [ブランチ(既定: develop)]
#
# annoyindex(cgo)はビルドタグ mlindex に隔離済みのため、通常ビルドは
# CGO_ENABLED=0 で成立し、MacからDocker/colima不要で数秒でクロスコンパイルできる。
# (類似記事インデックスが必要になったら -tags mlindex + Linux環境でビルドすること)
set -euo pipefail

HOST="${1:?使い方: ./deploy-app.sh <VMのIP> [ブランチ]}"
BRANCH="${2:-develop}"
OUT_DIR="$(mktemp -d "$HOME/.cache/news-app-deploy.XXXXXX")"
trap 'rm -rf "$OUT_DIR"' EXIT

echo "=== 1. linux/amd64 バイナリをクロスコンパイル(cgoなし・Docker不要)==="
SRC_DIR="$OUT_DIR/src"
git clone --depth 1 -b "$BRANCH" https://github.com/ponyo877/news-app-backend-refactor.git "$SRC_DIR"
(cd "$SRC_DIR" && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o "$OUT_DIR/news-app" ./api)
ls -lh "$OUT_DIR/news-app"

echo "=== 2. 転送と再起動 ==="
scp "$OUT_DIR/news-app" "$HOST":/tmp/news-app
ssh "$HOST" "sudo install -m 755 -o newsapp -g newsapp /tmp/news-app /opt/news-app/news-app && rm /tmp/news-app && sudo systemctl restart news-app && sleep 2 && systemctl is-active news-app && curl -fsS -m 10 http://127.0.0.1:8000/health"

echo "=== 完了 ==="
