#!/usr/bin/python3
""" Review module for the HBNB project """
from models.base_model import BaseModel, Base
from sqlalchemy import String, Column, ForienKey


class Review(BaseModel, Base):
    """ Review classto store review information """
    __tablename__ = "reviews"
    place_id = column(String(128), ForienKey("places.id"), nullable=False)
    user_id = column(String(128), ForienKey("users.id"), nullable=False)
    text = column(String(128), nullable=False)
