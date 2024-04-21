#!/usr/bin/python3
from flask import Flask
""" Starts a Flask Web Application """

app = Flask(__name__)


@app.route("/", strict_slashes=False)
def index():
    ''' Return Hello HBNB! '''
    return "Hello HBNB!"


if __name__ == "__main__":
    app.run(host='0.0.0.0')