from sqlalchemy import Column, String, Float
from sqlalchemy.orm import declarative_base

Base = declarative_base()

class Product(Base):
    __tablename__ = "products"

    id = Column(String, primary_key=True)
    title = Column(String)
    description = Column(String)
    price = Column(Float)
    platform = Column(String)
    image_url = Column(String)
    category = Column(String)