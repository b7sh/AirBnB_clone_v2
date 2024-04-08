#!/usr/bin/python3
# a Fabric script (based on the file 1-pack_web_static.py)
# +that distributes an archive to your web servers,
# +using the function do_deploy
from fabric.api import run, env, local, put
from datetime import datetime
import os

env.hosts = ['52.90.0.95', '54.237.79.170']
env.user = 'ubuntu'


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


def do_deploy(archive_path):
    """ distributes an archive to your web servers """
    if os.path.exists(archive_path) is False:
        return False
    try:
        arch = archive_path.split('/')[1]
        a_p = "/tmp/{}".format(arch)
        fol = arch.split('.')[0]
        fol_path = "/data/web_static/releases/"

        put(archive_path, a_p)
        run("mkdir -p {}".format(fol_path)
        run("tar -xzf {} -C {}".format(a_p, fol_path))
        run("rm {}".format(a_p))
        run("mv -f {}web_static/* {}/".format(fol_path, fol_path))
        run("rm -rf {}web_static".format(fol_path))
        run("rm -rf /data/web_static/current")
        run("ln -s {} /data/web_static/current".format(fol_path))
        return True
    except:
        return False
