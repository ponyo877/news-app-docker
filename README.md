# news-app-infra

まとめくん(news-app)のインフラ構成一式。旧名 `news-app-docker`(2026-08-08 改名)。

## 現行構成(OCI・bare)

本番: `matome.folks-chat.com` → Cloudflare → **OCI VM(141.147.165.70・Ubuntu 24.04)**

- コンテナ不使用。Go バイナリ + apt の MySQL 8.0 / Redis / nginx を systemd で直接運用
- セットアップ・デプロイ・カットオーバー手順: **[iac/README.md](iac/README.md)**
- 日常デプロイ: `./iac/deploy-app.sh ubuntu@141.147.165.70`(Macからクロスコンパイル→scp→restart)

## レガシー構成(GCP・docker-compose)

旧本番: GCP VM(34.173.153.189・Ubuntu 18.04 EOL)。切替後も当面併走中。

- `docker-compose.yml` / `app/` / `mysql/` / `nginx/` / `redis/` はこのレガシー環境用
- VM上のチェックアウトはディレクトリ名 `~/news-app-docker` のまま(composeプロジェクト名が
  ディレクトリ名由来のため改名しない)
- 運用記録: `DEPLOY-2026-08.md` / `MEMO.md`(サーバIPが旧値の箇所あり・歴史資料)

## 関連リポジトリ

- [news-app-backend-refactor](https://github.com/ponyo877/news-app-backend-refactor) — Go API(`develop` が本番)
- news-app-frontend — React Native アプリ(横断ドキュメントは frontend の `docs/` に集約)
