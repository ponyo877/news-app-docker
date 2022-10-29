# Docker
## Install
ubuntuへのdockerのinstall: https://zenn.dev/shimakaze_soft/articles/02aebaedeb43b6
ubuntuでgcrのpull: https://cloud.google.com/sdk/gcloud/reference/auth/configure-docker
ubuntuへのdstatのinstall: https://yatta47.hateblo.jp/entry/2018/01/13/030000
## Command
docker exec -it $(docker ps | grep mysql | awk '{print $1}') mysql -u root -ppassword -D matome
docker-compose exec db bash -c "./docker-entrypoint-initdb.d/init-database.sh"
docker images -q | xargs docker rmi
docker ps -aq | xargs docker stop; docker ps -aq | xargs docker rm
docker build -t gcr.io/gke-test-287910/news-app:v0.0.6 --platform amd64 --no-cache app
docker push gcr.io/gke-test-287910/news-app:v0.0.6

# MySQL
## Login
mysql -h 127.0.0.1 -P 3306 -u root -ppassword -D matome
## Query
INSERT INTO sites (id, title, rss_url, image_url) VALUES ('9a9cdc02-7d6c-e7a5-271d-897be92e9eb7', '痛いニュース', 'http://blog.livedoor.jp/dqnplus/index.rdf', 'sample.com');
UPDATE sites SET last_updated_at = '2020-08-26 18:48:56.451738' WHERE id ='9a9cdc02-7d6c-e7a5-271d-897be92e9eb7';

# HTTP
## Command
curl -sS -XGET 'localhost:9200/article/_search?pretty'
curl localhost/v1/article/search?keyword=ブラジル | jq .
curl -XPOST -F upfile=@webdav/sample/WebDAVTest.png http://localhost/static

# Other
dstat -clm
sh bin/gatling.sh --run-mode local --simulation testScenario
ssh -i ~/.ssh/id_ed25519 keisuke877jp@35.197.79.235