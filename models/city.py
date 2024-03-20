#!/usr/bin/python3
""" City Module for HBNB project """
from models.base_model import BaseModel, Base
from sqlalchemy import Column, String, Integer
from sqlalchemy import ForeinKey

class City(BaseModel):
    """ The city class, contains state ID and name """
    __tablename__ = "cities"
    state_id = Column(String(60), ForeinKey('state.id'), nullable=False)
    name = Column(String(128), nullable=False)
