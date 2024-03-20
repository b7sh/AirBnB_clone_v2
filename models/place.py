#!/usr/bin/python3
""" Place Module for HBNB project """
from models.base_model import BaseModel, Base
from sqlalchemy import Column, String, Table, Integer, Float, ForeignKey
from sqlalchemy.orm import relationship
from os import getenv
import models


amenity_place = Table("place_amenity", Base.metadata,
                    Column("place_id", String(60),
                             ForeignKey("places.id"),
                             primary_key=True),
                    Column("amenity_id", String(60),
                           ForeignKey("amenities.id"),
                           primary_key=True))


class Place(BaseModel):
    """ A place to stay """
    __tablename__ = "places"
    city_id = Column(String(60), ForeignKey("cities.id"), nullable=False)
    user_id = Column(String(60), ForeignKey("users.id"), nullable=False)
    name = Column(String(128), nullable=False)
    description = Column(String(1024))
    number_rooms = Column(Integer, nullable=False, default=0)
    number_bathrooms = Column(Integer, nullable=False, default=0)
    max_guest = Column(Integer, nullable=False, default=0)
    price_by_night = Column(Integer, nullable=False, default=0)
    latitude = Column(Float)
    longitude = Column(Float)
    amenity_ids = []

    if getenv("HBNB_TYPE_STORAGE") == "db":
        reviews = relationship("Review", cascade='all, delete, delete-orphan',
                               backref="place")
        amenities = relationship("Amenity", cascade='all, delete, delete-orphan',
                               backref="place_amenities")