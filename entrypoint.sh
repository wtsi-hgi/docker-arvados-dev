#!/bin/bash

# Default entrypoint for docker-arvados-dev

# Check if we have read access to /dev/fuse 
if [ -r /dev/fuse -a -w /dev/fuse ]
then 
    echo "/dev/fuse permissions ok"
else
    echo "/dev/fuse must be accessible (did you start the container with \`docker run --privileged\`?)"
    exit 1
fi

# Start postgresql
echo "docker-arvados-dev entrypoint.sh: starting postgresql"
sudo /etc/init.d/postgresql start

# Update ~/arvados-dev git repo
echo "docker-arvados-dev entrypoint.sh: pulling in ~/arvados-dev"
cd ~/arvados-dev
git pull

if [ -n "${ARVADOS_DEV_GIT_REPO}" ] 
then
    echo "docker-arvados-dev entrypoint.sh: adding remote ${ARVADOS_DEV_GIT_REPO}"
    git remote add ${ARVADOS_DEV_GIT_REPO}
    remote=$(echo ${ARVADOS_DEV_GIT_REPO} | cut -f1 -d" ")
    echo "docker-arvados-dev entrypoint.sh: fetching from remote ${remote}"
    git fetch ${remote}
fi

echo "docker-arvados-dev entrypoint.sh: checking out ${ARVADOS_DEV_GIT_REV} (set ARVADOS_DEV_GIT_REV to override)"
git checkout ${ARVADOS_DEV_GIT_REV}

# Update ~/arvados git repo
echo "docker-arvados-dev entrypoint.sh: pulling in ~/arvados"
cd ~/arvados
git pull

if [ -n "${ARVADOS_GIT_REPO}" ] 
then
    echo "docker-arvados-dev entrypoint.sh: adding remote ${ARVADOS_GIT_REPO}"
    git remote add ${ARVADOS_GIT_REPO}
    remote=$(echo ${ARVADOS_GIT_REPO} | cut -f1 -d" ")
    echo "docker-arvados-dev entrypoint.sh: fetching from remote ${remote}"
    git fetch ${remote}
fi

echo "docker-arvados-dev entrypoint.sh: checking out ${ARVADOS_GIT_REV} (set ARVADOS_GIT_REV to override)"
git checkout ${ARVADOS_GIT_REV}

echo "docker-arvados-dev entrypoint.sh: starting Xvfb on :0.0"
sudo Xvfb -ac :0.0 &
export DISPLAY=:0.0

# Run remaining argument(s) in the shell
echo "docker-arvados-dev entrypoint.sh: passing CMD to bash -c \"$@\""
cd ~
bash -c "$@"
