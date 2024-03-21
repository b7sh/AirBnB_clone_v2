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
    """
        This class serializes instances to a JSON format
        Attributes:
            __file_path: path to the JSON file
            __objects: objects dictionary
    """
    __file_path = "file.json"
    __objects = {}

    def all(self, cls=None):
        """
            returns a dictionary
            or:
            returns a dictionary of __object
        """
        my_dict = {}
        if cls:
            dic = self.__objects
            for k in dic:
                separate = k.replace('.', ' ')
                separate = shlex.split(separate)
                if (separate[0] == cls.__name__):
                    my_dict[k] = self.__objects[k]
            return (my_dict)
        else:
            return self.__objects

    def new(self, obj):
        """
            sets __object to given obj
            Args:
                obj: object
        """
        if obj:
            key = "{}.{}".format(type(obj).__name__, obj.id)
            self.__objects[key] = obj

    def save(self):
        """serialize the file path to JSON file path
        """
        my_dict = {}
        for key, value in self.__objects.items():
            my_dict[key] = value.to_dict()
        with open(self.__file_path, 'w', encoding="UTF-8") as f:
            json.dump(my_dict, f)

    def reload(self):
        """
            serialize the file path to JSON file path
        """
        try:
            with open(self.__file_path, 'r', encoding="UTF-8") as f:
                for key, value in (json.load(f)).items():
                    value = eval(value["__class__"])(**value)
                    self.__objects[key] = value
        except FileNotFoundError:
            pass

    def delete(self, obj=None):
        """
            delete an existing element
        """
        if obj:
            key = "{}.{}".format(type(obj).__name__, obj.id)
            del self.__objects[key]

    def close(self):
        """
            calls reload()
        """
        self.reload()