#!/usr/bin/python3
# a Fabric script that generates a .tgz archive
#+ from the contents of the web_static folder
from fabric.api import local
from datetime import datetime


def do_pack():
    """ generate a .tgz archive """
    t_now = datetime.now().strftime("%Y%m%d%H%M%S")
    path = "versions/web_static_{}.tgz".format(t_now)
    local("mkdir -p versions")
    acheive = local("tar -cvzf {} web_static".format(path))
    if acheive.return_code != 0:
        return None
    else:
        return path
