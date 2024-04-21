#!/usr/bin/python3
""" Starts a Flask Web Application """

from flask import Flask, render_template

app = Flask(__name__)


@app.route("/", strict_slashes=False)
def index():
    ''' Return Hello HBNB! '''
    return "Hello HBNB!"


@app.route("/hbnb", strict_slashes=False)
def hbnb():
    ''' Return HBNB '''
    return "HBNB"


# @app.route("/python/", defaults={'text': 'is_cool'}, strict_slashes=False)
# @app.route("/python/<text>", strict_slashes=False)
# def value(text):
#     '''
#         display "Python" ” followed by
#         the value of the text variable
#     '''
#     text = text.replace("_", " ")
#     return "Python {}".format(text)


# @app.route("/number/<int:n>", strict_slashes=False)
# def value(n):
#     '''
#         display "n is a number" only if
#         the type of n is integer
#     '''
#     if isinstance(n, int):
#         return "{} is a number".format(n)


@app.route("/number_template/<int:n>", strict_slashes=False)
def value(n=None):
    '''
        display "n is a number" only if
        the type of n is integer
    '''
    return render_template("5-number.html", n=n)


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
