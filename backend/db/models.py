"""SQLAlchemy models mirroring postgres/schema.sql.

The database schema is canonical (applied via scripts/init_db.py).
These models exist so future ``Base.metadata.create_all`` calls and any
ORM usage stay consistent with the real tables.
"""

from sqlalchemy import (
    Column,
    String,
    Float,
    Text,
    TIMESTAMP,
    Integer,
    UUID,
    func,
)
from sqlalchemy.orm import declarative_base

from pgvector.sqlalchemy import Vector


Base = declarative_base()


class Product(Base):
    """Final, searchable catalog. ``embedding`` is a normalized
    512-dim CLIP vector (openai/clip-vit-base-patch32)."""

    __tablename__ = "products"

    id = Column(String, primary_key=True)
    title = Column(String)
    description = Column(String)
    price = Column(Float)
    platform = Column(String)
    image_url = Column(String)
    category = Column(String)
    brand = Column(String)
    source_url = Column(String)
    original_image_url = Column(String)
    local_image_path = Column(String)
    embedding = Column(Vector(512))
    created_at = Column(TIMESTAMP, server_default=func.now())


class ProductRaw(Base):
    """Staging table for the ingestion pipeline:
    csv import -> download -> embed -> finalize (into products)."""

    __tablename__ = "products_raw"

    id = Column(UUID, primary_key=True)
    title = Column(String)
    brand = Column(String)
    category = Column(String)
    description = Column(Text)
    price = Column(Float)
    platform = Column(String)
    source_url = Column(String)
    image_url = Column(String)
    local_image_path = Column(String)
    # pending|downloading|downloaded|embedding|embedded|failed
    status = Column(String, server_default="pending")
    # success|failed
    embedding_status = Column(String)
    failure_reason = Column(Text)
    downloaded_at = Column(TIMESTAMP)
    embedded_at = Column(TIMESTAMP)
    embedding = Column(Vector(512))
    created_at = Column(TIMESTAMP, server_default=func.now())


class SearchLog(Base):
    """Lightweight analytics: one row per search request."""

    __tablename__ = "search_logs"

    id = Column(
        UUID,
        primary_key=True,
        server_default=func.gen_random_uuid(),
    )
    query_time = Column(TIMESTAMP, server_default=func.now())
    result_count = Column(Integer)
    top_similarity = Column(Float)


class QuerySearch(Base):
    """Persists user-submitted searches and their CLIP image
    embeddings for matching and audit."""

    __tablename__ = "query_searches"

    id = Column(
        UUID,
        primary_key=True,
        server_default=func.gen_random_uuid(),
    )
    query_text = Column(String)
    query_embedding = Column(Vector(512))
    top_similarity = Column(Float)
    created_at = Column(TIMESTAMP, server_default=func.now())
