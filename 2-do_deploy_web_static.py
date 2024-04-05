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
    archeive = local("tar -cvzf {} web_static".format(path))
    if archeive.return_code != 0:
        return None
    else:
        return path


def do_deploy(archive_path):
    """ distributes an archive to your web servers """
    if os.path.exists(archive_path):
        path = archive_path.split('/')[1]
        c_path = "/tmp/{}".format(path)
        fol = path.split('.')[0]
        fol_path = "/data/web_static/releases/{}/".format(fol)

        put(archive_path, c_path)
        run("mkdir -p {}".format(fol_path))
        run("tar -xzf {} -C {}".format(c_path, fol_path))
        run("rm {}".format(f_p))
        run("mv -f {}web_static/* {}".format(fol_path, fol_path))
        run("rm -rf {}web_static".format(fol_path))
        run("rm -rf /data/web_static/current")
        run("ln -s {} /data/web_static/current".format(fol_path))
        return True
    return False
