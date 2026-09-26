-- ============================================================
-- ShopSense database schema
-- PostgreSQL 15 + pgvector
-- Run on a fresh database to recreate the full MVP schema.
-- ============================================================

-- Extension: pgvector for CLIP embedding similarity search
CREATE EXTENSION IF NOT EXISTS vector;


-- ------------------------------------------------------------
-- 1. products_raw
--    Staging table for the ingestion pipeline:
--    csv import -> download -> embed -> finalize (into products)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products_raw (
    id                UUID PRIMARY KEY,
    title             VARCHAR,
    brand             VARCHAR,
    category          VARCHAR,
    description       TEXT,
    price             DOUBLE PRECISION,
    platform          VARCHAR,
    source_url        VARCHAR,
    image_url         VARCHAR,
    local_image_path  VARCHAR,
    status            VARCHAR DEFAULT 'pending',   -- pending|downloading|downloaded|embedding|embedded|failed
    embedding_status  VARCHAR,                      -- success|failed
    failure_reason    TEXT,
    downloaded_at     TIMESTAMP,
    embedded_at       TIMESTAMP,
    embedding         VECTOR,
    created_at        TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS products_raw_status_idx
    ON products_raw (status);


-- ------------------------------------------------------------
-- 2. products
--    Final, searchable catalog. `embedding` is a normalized
--    512-dim CLIP vector. Searched via HNSW cosine index.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id                  VARCHAR PRIMARY KEY,
    title               VARCHAR,
    description         VARCHAR,
    price               DOUBLE PRECISION,
    platform            VARCHAR,
    image_url           VARCHAR,
    category            VARCHAR,
    brand               VARCHAR,
    source_url          VARCHAR,
    original_image_url  VARCHAR,
    local_image_path    VARCHAR,
    embedding           VECTOR,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- HNSW index for approximate nearest-neighbour search on CLIP vectors.
-- vector_cosine_ops matches the cosine distance (1 - cosine_sim) used
-- throughout the Python services.
CREATE INDEX IF NOT EXISTS products_embedding_hnsw_idx
    ON products
    USING hnsw (embedding vector_cosine_ops);


-- ------------------------------------------------------------
-- 3. search_logs
--    Lightweight analytics: one row per search request.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS search_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_time      TIMESTAMP DEFAULT NOW(),
    result_count    INTEGER,
    top_similarity  DOUBLE PRECISION
);


-- ------------------------------------------------------------
-- 4. query_searches
--    Persists every user-submitted search query and its CLIP image
--    embedding, so live-scraped results can be matched against the
--    query embedding and the search history is auditable.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS query_searches (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_text      VARCHAR,
    query_embedding VECTOR,
    top_similarity  DOUBLE PRECISION,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS query_searches_created_idx
    ON query_searches (created_at DESC);

