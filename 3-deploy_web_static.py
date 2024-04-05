#!/usr/bin/python3
# reates and distributes an archive to your web servers
from fabric.api import run, put, local, env
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


def deploy():
    """ reates and distributes an archive """
    archive_path = do_pack()
    if archive_path is None:
        return False
    return do_deploy(archive_path)
