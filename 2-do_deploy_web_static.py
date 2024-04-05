#!/usr/bin/python3
# a Fabric script (based on the file 1-pack_web_static.py)
# +that distributes an archive to your web servers,
# +using the function do_deploy
from fabric.api import run, env, local, put
from datetime import datetime
import os

env.hosts = ['52.90.0.95', '54.237.79.170']
env.user = 'ubuntu'


def do_deploy(archive_path):
    """ distributes an archive to your web servers """
    if os.path.exists(archive_path):
        path = archive_path.split('/')[-1]
        fol = path.split('.')[0]
        fol_path = "/data/web_static/releases/"

        put(archive_path, '/tmp/')
        run("mkdir -p {}{}/".format(fol_path, fol))
        run("tar -xzf /tmp/{} -C {}{}/".format(path, fol_path, fol))
        run("rm /tmp/{}".format(path))
        run("mv {0}{1}/web_static/* {0}{1}/".format(fol_path, fol))
        run("rm -rf {}{}/web_static".format(fol_path, fol))
        run("rm -rf /data/web_static/current")
        run("ln -s {}{}/ /data/web_static/current".format(fol_path, fol))
        return True
    return False
