#!/usr/bin/python3
""" State Module for HBNB project """
from models.base_model import BaseModel, Base
from sqlalchemy import Column, String, Integer
import shlex
from models.city import City
import models


class State(BaseModel):
    """ State class """
    __tablename__ = "states"
    name = Column(String(128), nullable=False)