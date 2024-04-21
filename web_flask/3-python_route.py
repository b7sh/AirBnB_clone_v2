#!/usr/bin/python3
""" Starts a Flask Web Application """

from flask import Flask

app = Flask(__name__)


@app.route("/", strict_slashes=False)
def index():
    ''' Return Hello HBNB! '''
    return "Hello HBNB!"


@app.route("/hbnb", strict_slashes=False)
def hbnb():
    ''' Return HBNB '''
    return "HBNB"


@app.route("/python/<text>", strict_slashes=False)
def value(text):
    '''
        display “C ” followed by
        the value of the text variable
    '''
    text = text.replace("_", " ")
    return "Python {}".format(text)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
