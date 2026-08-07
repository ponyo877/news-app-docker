# bare-metal 移行 IaC(コンテナ廃止)

作成: 2026-08-08。docker-compose 構成(app/mysql/redis/nginx の4コンテナ)を、
**新VM上で systemd 直載せ(bare)** に置き換えるためのセットアップ一式。

## なぜ bare にするか(2026-08-08 判断)

- 単一VM・固定4サービス・スケール不要のワークロードで、コンテナの利点(隔離・可搬性)がほぼ活きない
- dockerd + shim が常時 約100MB(1GB VM の1割)を消費。restart:always も dockerd が単一障害点
- デプロイが「イメージビルド→転送→pull/up」から「**Goバイナリを scp → systemctl restart**」になる
  (実測: 1GB VM上の docker build は go build だけで30分超・load 10 で本番を巻き込んだ)
- 再現性はこの iac/ ディレクトリで担保する

## 対象構成

| サービス | 旧(container) | 新(bare) |
|---|---|---|
| API | news-app:v0.0.x イメージ | `/opt/news-app/news-app`(Goバイナリ)+ `news-app.service` |
| DB | mysql:5.7(512MB制限) | apt の mysql-server-8.0 + `mysql/matome.cnf` |
| KVS | redis:latest(128MB制限) | apt の redis-server + requirepass |
| Web | nginx イメージ + WebDAV | apt の nginx(dav付き)+ `nginx/matome.conf` |
| クロール | systemd stock.timer(既存) | 同じ(`units/stock.*`、CRON_TOKENヘッダー付き) |
| 監視 | cron(check-crawl-health) | `units/crawl-health.*` タイマー |

## 新VM要件

- GCP e2-small(2GB)以上、**Ubuntu 24.04 LTS**、ディスク30GB
- ファイアウォール: 80/tcp(Cloudflare→オリジン)、22/tcp のみ
- 旧VM(34.173.153.189)は移行完了まで稼働継続

## カットオーバー手順

```bash
# === 新VM上 ===
# 1. リポジトリ取得とセットアップ(mysql/redis/nginx/ユニット一式が入る)
git clone https://github.com/ponyo877/news-app-docker.git ~/news-app-docker
cd ~/news-app-docker/iac
sudo ./setup.sh                      # 冪等。環境ファイルの雛形が /etc/news-app/env に置かれる
sudo vi /etc/news-app/env            # パスワード・CRON_TOKEN を実値に

# === ローカルMac ===
# 2. Goバイナリをビルドして配備(cgoのためlinux/amd64はコンテナ内でビルドする)
./deploy-app.sh <新VMのIP>

# === 旧VM → 新VM のデータ移行 ===
# 3. MySQL(論理ダンプ。5.7→8.0 はこの方法が安全)
ssh 旧VM "mysqldump -h127.0.0.1 -uroot -p<pass> --single-transaction matome | gzip" | \
  ssh 新VM "gunzip | mysql -uroot -p<pass> matome"
# 4. 静的ファイル(アイコン・scraper-rules.json・プライバシーHTML)と /srv(BERTモデル・annoyインデックス)
ssh 旧VM "tar cz -C ~/news-app-docker/nginx data" | ssh 新VM "tar xz -C /var/www/ --strip-components=1"
ssh 旧VM "tar cz -C ~/news-app-docker/app data"   | ssh 新VM "sudo tar xz -C /srv --strip-components=1"
# 5. Redis(ランキングZSET): 旧VMの dump.rdb をコピー(なければ諦めてもランキングは再蓄積される)
ssh 旧VM "sudo docker exec news-app-docker_redis_1 redis-cli -a <pass> save && sudo cat ~/news-app-docker/redis/data/dump.rdb" | \
  ssh 新VM "sudo tee /var/lib/redis/dump.rdb > /dev/null && sudo systemctl restart redis-server"

# === 動作確認(新VMに直接) ===
curl -s http://<新VMのIP>/health
curl -s "http://<新VMのIP>/v1/article" | head -c 300

# === 切替 ===
# 6. Cloudflare DNS: matome.folks-chat.com の Aレコードを新VMのIPへ(Proxied維持)
# 7. 監視: crawl-health のログと journalctl -u news-app を数時間観察
# 8. 問題なければ旧VMを数日後に停止・削除
```

## 日常のデプロイ(移行後)

```bash
cd ~/Documents/workspace/news-app-docker/iac
./deploy-app.sh <VMのIP>     # ビルド→scp→systemctl restart news-app まで一発
```

## 注意

- MySQL 8.0 化で `mysql_native_password` 明示は不要(アプリはgo-sql-driverで caching_sha2 対応)
- 旧 my.cnf の `innodb_ft_min_token_size=2` + ngram は `mysql/matome.cnf` に引き継いでいる。
  **FULLTEXTインデックスはダンプ投入後に `OPTIMIZE TABLE articles;` で再構築すること**
- nginx の WebDAV PUT(`POST /v1/static` のアップロード先)は `/var/www/static` への
  www-data 書き込み権限が前提(setup.sh が設定する)
