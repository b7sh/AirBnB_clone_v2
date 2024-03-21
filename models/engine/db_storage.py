#!/usr/bin/python3
""" new class for sqlAlchemy """
from os import getenv
from sqlalchemy.orm import sessionmaker, scoped_session
from sqlalchemy import (create_engine)
from sqlalchemy.ext.declarative import declarative_base
from models.base_model import Base
from models.state import State
from models.city import City
from models.user import User
from models.place import Place
from models.review import Review
from models.amenity import Amenity


class DBStorage:
    """ create tables in environmental"""
    __engine = None
    __session = None

    def __init__(self):
        user = getenv("HBNB_MYSQL_USER")
        passwd = getenv("HBNB_MYSQL_PWD")
        db = getenv("HBNB_MYSQL_DB")
        host = getenv("HBNB_MYSQL_HOST")
        env = getenv("HBNB_ENV")

        self.__engine = create_engine('mysql+mysqldb://{}:{}@{}/{}'
                                      .format(user, passwd, host, db),
                                      pool_pre_ping=True)

        if env == "test":
            Base.metadata.drop_all(self.__engine)

    def all(self, cls=None):
        """
            returns a dictionary
            or:
            returns a dictionary of __object
        """
        all_dic = {}
        if cls:
            if type(cls) is str:
                cls = eval(cls)
            query = self.__session.query(cls)
            for element in query:
                k = "{}.{}".format(type(element).__name__, element.id)
                all_dic[k] = element
        else:
            all_list = [State, City, User, Place, Review, Amenity]
            for clas in all_list:
                query = self.__session.query(clas)
                for element in query:
                    k = "{}.{}".format(type(element).__name__, element.id)
                    all_dic[k] = element
        return (all_dic)

    def new(self, obj):
        """
            add a new element
        """
        self.__session.add(obj)

    def save(self):
        """
            commit changes
        """
        self.__session.commit()

    def delete(self, obj=None):
        """
            delete an element
        """
        if obj:
            self.session.delete(obj)

    def reload(self):
        """
            configration
        """
        Base.metadata.create_all(self.__engine)
        sec = sessionmaker(bind=self.__engine, expire_on_commit=False)
        Session = scoped_session(sec)
        self.__session = Session()

    def close(self):
        """ 
            close session
        """
        self.__session.close()