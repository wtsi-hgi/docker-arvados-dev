#!/bin/bash

# Default entrypoint for docker-arvados-dev

# Start postgresql
echo "docker-arvados-dev entrypoint.sh: starting postgresql"
sudo /etc/init.d/postgresql start

# Update ~/arvados-dev git repo
echo "docker-arvados-dev entrypoint.sh: pulling in ~/arvados-dev"
cd ~/arvados-dev
git pull

# Update ~/arvados git repo and checkout ARVADOS_DEV_REVISION
echo "docker-arvados-dev entrypoint.sh: pulling in ~/arvados"
cd ~/arvados
git pull

echo "docker-arvados-dev entrypoint.sh: checking out ${ARVADOS_DEV_REVISION} (set ARVADOS_DEV_REVISION to override)"
git checkout ${ARVADOS_DEV_REVISION}

# Run remaining argument(s) in the shell
echo "docker-arvados-dev entrypoint.sh: passing CMD to bash -c \"$@\""
cd ~
bash -c "$@"
