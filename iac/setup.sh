#!/usr/bin/env bash
# 新VM(Ubuntu 24.04)を bare 構成でセットアップする(冪等)。
# 使い方: sudo ./setup.sh
set -euo pipefail
cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
  echo "sudo で実行してください" >&2
  exit 1
fi

echo "=== 1. パッケージ ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -yq mysql-server redis-server nginx curl python3

echo "=== 2. ディレクトリとユーザー ==="
useradd --system --home /opt/news-app --shell /usr/sbin/nologin newsapp 2>/dev/null || true
mkdir -p /opt/news-app /etc/news-app /srv/models /var/www/static
chown newsapp:newsapp /opt/news-app /srv /srv/models
# WebDAV PUT(POST /v1/static のアップロード)先。nginx(www-data)が書く
chown -R www-data:www-data /var/www/static

echo "=== 3. 環境ファイル ==="
if [ ! -f /etc/news-app/env ]; then
  cp env.example /etc/news-app/env
  chmod 600 /etc/news-app/env
  echo "!!! /etc/news-app/env を編集してパスワード・CRON_TOKEN を設定してください !!!"
fi

echo "=== 4. MySQL ==="
install -m 644 mysql/matome.cnf /etc/mysql/mysql.conf.d/matome.cnf
systemctl enable --now mysql
systemctl restart mysql
# DB作成(rootはsocket認証なのでsudo経由で通る)
mysql -e "CREATE DATABASE IF NOT EXISTS matome DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;"
echo "アプリ用ユーザーは /etc/news-app/env の DB_PASSWORD を決めてから以下を実行:"
echo "  mysql -e \"CREATE USER IF NOT EXISTS 'matome'@'localhost' IDENTIFIED BY '<DB_PASSWORD>'; GRANT ALL ON matome.* TO 'matome'@'localhost';\""

echo "=== 5. Redis ==="
# requirepass を環境ファイルと合わせる(初期値はenv.exampleのまま)
if ! grep -q "^requirepass" /etc/redis/redis.conf; then
  echo "requirepass CHANGE_ME_REDIS" >> /etc/redis/redis.conf
  echo "!!! /etc/redis/redis.conf の requirepass を /etc/news-app/env と同じ値にしてください !!!"
fi
systemctl enable --now redis-server

echo "=== 6. nginx ==="
install -m 644 nginx/matome.conf /etc/nginx/sites-available/matome.conf
ln -sf /etc/nginx/sites-available/matome.conf /etc/nginx/sites-enabled/matome.conf
rm -f /etc/nginx/sites-enabled/default
# 既存リポジトリのプライバシーポリシー等を配置
mkdir -p /var/www/static/privacy_policy /var/www/static/eula
cp ../nginx/privacy_policy.html /var/www/static/privacy_policy/index.html 2>/dev/null || true
cp ../nginx/eula.html /var/www/static/eula/index.html 2>/dev/null || true
nginx -t && systemctl enable --now nginx && systemctl reload nginx

echo "=== 7. systemd ユニット ==="
install -m 644 units/news-app.service /etc/systemd/system/
install -m 644 units/stock.service /etc/systemd/system/
install -m 644 units/stock.timer /etc/systemd/system/
install -m 644 units/crawl-health.service /etc/systemd/system/
install -m 644 units/crawl-health.timer /etc/systemd/system/
install -m 755 ../../news-app-backend-refactor/scripts/check-crawl-health.sh /opt/news-app/check-crawl-health.sh 2>/dev/null || \
  echo "check-crawl-health.sh は backend リポジトリから /opt/news-app/ へ手動配置してください"
systemctl daemon-reload
systemctl enable stock.timer crawl-health.timer
# news-app.service はバイナリ配備後に deploy-app.sh が起動する

echo "=== 完了 ==="
echo "次: /etc/news-app/env 編集 → MySQLユーザー作成 → ローカルから ./deploy-app.sh <IP>"
