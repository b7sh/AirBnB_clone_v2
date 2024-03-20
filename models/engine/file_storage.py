#!/usr/bin/python3
"""This is the file storage class for AirBnB"""
import json
from models.base_model import BaseModel
from models.user import User
from models.state import State
from models.city import City
from models.amenity import Amenity
from models.place import Place
from models.review import Review
import shlex


class FileStorage:
    """This class serializes instances to a JSON file and
    deserializes JSON file to instances
    Attributes:
        __file_path: string
        __objects: dictionary
    """
    __file_path = "file.json"
    __objects = {}

    def all(self, cls=None):
        """
            returns a dictionary
            or returns a dictionary of __object
        """
        all_dic = {}
        if cls:
            dic = self.__objects
            for k in dic:
                pa = k.replace('.', ' ')
                pa = shlex.split(pa)
                if (pa[0] == cls.__name__):
                    all_dic[k] = self.__objects[k]
            return (all_dic)
        else:
            return self.__objects

    def new(self, obj):
        """sets __object to given obj
        Args:
            obj: object
        """
        if obj:
            k = "{}.{}".format(type(obj).__name__, obj.id)
            self.__objects[k] = obj

    def save(self):
        """
            serialize the file to JSON file path
        """
        dictionary = {}
        for k, v in self.__objects.items():
            dictionary[k] = v.to_dict()
        with open(self.__file_path, 'w', encoding="UTF-8") as f:
            json.dump(dictionary, f)

    def reload(self):
        """serialize the file path to JSON file path
        """
        try:
            with open(self.__file_path, 'r', encoding="UTF-8") as f:
                for k, v in (json.load(f)).items():
                    v = eval(v["__class__"])(**v)
                    self.__objects[k] = v
        except FileNotFoundError:
            pass

    def delete(self, obj=None):
        """ 
            delete an element
        """
        if obj:
            k = "{}.{}".format(type(obj).__name__, obj.id)
            del self.__objects[k]

    def close(self):
        """ 
            call reload()
        """
        self.reload()