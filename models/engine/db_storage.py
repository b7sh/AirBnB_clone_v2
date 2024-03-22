#!/usr/bin/python3
"""
    This module defines a class to manage 
    database storage for hbnb clone
"""
from models.base_model import Base
from models.city import City
from models.user import User
from models.place import Place
from models.state import State
from models.review import Review
from models.amenity import Amenity
from sqlalchemy import (create_engine)
from os import getenv
from sqlalchemy.orm import sessionmaker, scoped_session


class DBStorage:
    """ create new database engine """
    __engine = None
    __session = None

    def __init__(self):
        user = getenv("HBNB_MYSQL_USER")
        passwd = getenv("HBNB_MYSQL_PWD")
        host = getenv("HBNB_MYSQL_HOST")
        db = getenv("HBNB_MYSQL_DB")
        env = getenv("HBNB_ENV")

        self.__engine = create_engine('mysql+mysqldb://{}:{}@{}/{}'
                                      .format(user, passwd, host, db),
                                      pool_pre_ping=True)
        
        print(self.__engine)

        if env == "test":
            Base.metadata.drop_all(self.__engine)

    def all(self, cls=None):
        """
            return a dictionary
            or a dictionary of objects
        """
        all_dict = {}
        if cls:
            if type(cls) is str:
                cls = eval(cls)
            query = self.__session.query(cls)
            for ele in query:
                k = "{}.{}".format(type(ele).__name__, ele.id)
                all_dict[k] = ele
        else:
            all_list = [State, City, User, Place, Review, Amenity]
            for clas in all_list:
                query = self.__session.query(clas)
                for ele in query:
                    k = "{}.{}".format(
                        type(ele),__name__, ele.id
                    )
                    all_dict[k] = ele
        return all_dict

    def new(self, obj):
        """ add new element to the table """
        if obj:
            self.__session.add(obj)

    def save(self):
        """
            save the new table
        """
        self.__session.commit()

    def delete(self, obj=None):
        """ delete an element from the table """
        if obj:
            self.__session.delete(obj)

    def reload(self):
        """ create all tables in the database """
        Base.metadata.create_all(self.__engine)
        sec = sessionmaker(bind=self.__engine, expire_on_commit=False)
        Session = scoped_session(sec)
        self.__session = Session()

    def close(self):
        """ reload() """
        self.reload()
