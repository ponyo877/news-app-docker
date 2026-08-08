# matome-recs — まとめくん推薦基盤

Cloudflare Workers AI(bge-m3)+ Vectorize によるコンテンツベース推薦。
アプリの for You タブと記事画面の「⚡関連記事」がここを呼ぶ。
VM(OCI)には一切負荷をかけない。障害時はアプリが端末内リランクへ自動縮退する。

## API

- `POST /recs/foryou` — body `{ "recentArticleIds": ["uuid", ...] }`(新しい順・最大20件)
  → ユーザーベクトル(時間減衰平均)で topK 検索。既読除外・同一サイト上限3。`{ data: ArticleMeta[] }`
- `POST /recs/related` — body `{ "articleId": "uuid", "recentArticleIds": [...] }`
  → 記事ベクトル×0.7 + ユーザーベクトル×0.3 の「人×記事」推薦。`{ data: ArticleMeta[] }`(最大10件)
- ベクトルが引けないときは 404(アプリはフォールバック)

## コスト(2026-08 検証)

- Workers AI bge-m3: 記事2,500件/日 ≈ 無料枠(10K Neurons/日)の1%
- Vectorize **Free: 5M stored dims = 約4,800記事 = 保持2日分**(`RETENTION_MS`)
- Workers Paid($5/月)に昇格したら `src/index.ts` の `RETENTION_MS` を14日へ変えるだけ
- クエリ枠 Free 30M dims/月 ≈ DAU 50 相当。超過し始めたら効果が出ている証拠なので Paid へ

## 初回デプロイ手順

```bash
cd workers/recs
npm install

# 1. Vectorize index(1024次元・cosine)
npx wrangler vectorize create matome-articles --dimensions=1024 --metric=cosine
# 2. 掃除cronのレンジフィルタ用 metadata index
npx wrangler vectorize create-metadata-index matome-articles --property-name=publishedAtTs --type=number
# 3. KV(取り込みカーソル保存)
npx wrangler kv namespace create RECS_KV
#    → 出力された id を wrangler.jsonc の REPLACE_WITH_KV_NAMESPACE_ID に貼る
# 4. デプロイ
npx wrangler deploy
```

## 動作確認

```bash
# 取り込み(cron を待たず手動トリガー)
npx wrangler tail   # 別ターミナルでログ監視
# 5分待つか、dev環境: npx wrangler dev --test-scheduled → curl "http://localhost:8787/__scheduled?cron=*%2F5+*+*+*+*"

# 推薦(記事UUIDは /v1/article から拾う)
curl -s -X POST https://matome-recs.<account>.workers.dev/recs/foryou \
  -H 'Content-Type: application/json' \
  -d '{"recentArticleIds":["<uuid1>","<uuid2>"]}' | jq .
curl -s -X POST https://matome-recs.<account>.workers.dev/recs/related \
  -H 'Content-Type: application/json' \
  -d '{"articleId":"<uuid>","recentArticleIds":[]}' | jq .
```

## 運用メモ

- 取り込みカーソル: KV キー `lastPublishedAt`(ISO文字列)。壊れたら削除すれば最新15件から再開
- インデックスを作り直すときは KV のカーソルも消すこと
- Vectorize の使用量: ダッシュボード → Workers & Pages → Vectorize → matome-articles
