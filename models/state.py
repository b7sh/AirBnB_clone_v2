#!/usr/bin/python3
""" State Module for HBNB project """
from models.base_model import BaseModel, Base
from sqlalchemy import Column, String, Integer
import shlex
from models.city import City
import models
from sqlalchemy.orm import relationship


class State(BaseModel):
    """ State class """
    __tablename__ = "states"
    name = Column(String(128), nullable=False)
    cities = relationship("City", cascade='all, delete, delete-orphan',
                          backref="state")
    
    @property
    def cities(self):
        variable = models.storage.all()
        all_list = []
        re = []
        for k in variable:
            city = k.replace('.', ' ')
            city = shlex.split(city)
            if(city[0] == 'City'):
                all_list.append(variable[k])
        for ele in all_list:
            if (ele.state_id == self.id):
                re.append(ele)
        return re