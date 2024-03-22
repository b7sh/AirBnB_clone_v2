#!/usr/bin/python3
""" Review module for the HBNB project """
from models.base_model import BaseModel, Base
from sqlalchemy import String, Column, ForeignKey


class Review(BaseModel, Base):
    """ Review classto store review information """
    __tablename__ = "reviews"
    place_id = Column(String(128), ForeignKey("places.id"), nullable=False)
    user_id = Column(String(128),ForeignKey("users.id"), nullable=False)
    text = Column(String(128), nullable=False)
