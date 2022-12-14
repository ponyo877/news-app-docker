CREATE TABLE IF NOT EXISTS matome.articles (
    id           VARCHAR(36)   NOT NULL,
    title        VARCHAR(100)  NOT NULL,
    url          VARCHAR(100)  NOT NULL,
    image_url    VARCHAR(100)  NOT NULL,
    site_id      VARCHAR(36)   NOT NULL,
    published_at TIMESTAMP(6)  DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    updated_at   TIMESTAMP(6)  DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    created_at   TIMESTAMP(6)  DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id),
    FULLTEXT KEY (title) WITH PARSER ngram
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE INDEX idx_site_id_published_at ON matome.articles (site_id, published_at);
CREATE INDEX idx_published_at ON matome.articles (published_at);

CREATE TABLE IF NOT EXISTS matome.sites (
    id              VARCHAR(36)  NOT NULL,
    title           VARCHAR(100) NOT NULL,
    rss_url         VARCHAR(100) NOT NULL,
    image_url       VARCHAR(100) NOT NULL,
    last_updated_at TIMESTAMP(6) DEFAULT '2007-12-31 23:59:59.999999' NOT NULL,
    updated_at      TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    created_at      TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS matome.users (
    id          VARCHAR(36)  NOT NULL,
    name        VARCHAR(100) NOT NULL,
    image_url   VARCHAR(100) NOT NULL,
    device_hash VARCHAR(100) NOT NULL UNIQUE,
    updated_at  TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    created_at  TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE INDEX idx_device_hash ON matome.users (device_hash);

CREATE TABLE IF NOT EXISTS matome.comments (
    id          VARCHAR(36)  NOT NULL,
    article_id  VARCHAR(36)  NOT NULL,
    user_name   VARCHAR(100) NOT NULL,
    image_url   VARCHAR(100) NOT NULL,
    device_hash VARCHAR(100) NOT NULL,
    message     TEXT         NOT NULL,
    updated_at  TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    created_at  TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE INDEX idx_article_id ON matome.comments (article_id);