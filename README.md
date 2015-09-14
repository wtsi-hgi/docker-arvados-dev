# docker-arvados-dev
Docker container for Arvados development (and running tests)

Sets up an [Arvados](https://arvados.org/) development/testing environment within a Docker container. 

Developed based on documentation on [Arvados Hacking Prerequisites](https://dev.arvados.org/projects/arvados/wiki/Hacking_prerequisites) and [Running Arvados Tests](https://dev.arvados.org/projects/arvados/wiki/Running_tests). Uses a Debian Jessie base image and configures a custom entrypoint to which is passed a shell command to run in the test environment.

To build the docker container locally:
```bash
git clone https://github.com/wtsi-hgi/docker-arvados-dev.git
docker build -t local/docker-arvados-dev docker-arvados-dev
```

To run all tests against the master branch (of https://github.com/curoverse/arvados):
```bash
 docker run -it --privileged local/docker-arvados-dev
 ```
or, equivalently:
```bash
docker run -it --privileged local/docker-arvados-dev time ~/arvados-dev/jenkins/run-tests.sh WORKSPACE=~/arvados
```

N.B. passing '--privileged' to `docker run` is required in order for the test framework to access FUSE (via `/dev/fuse`). 

To run all tests against the staging branch:
```bash
 docker run -it --privileged -e ARVADOS_GIT_REV="staging" local/docker-arvados-dev
 ```
 
 To fetch both `~/arvados` and `~/arvados-dev` from an alternative git repo and checkout a specific revision/tag/branch:
 ```bash
docker run -it --privileged -e ARVADOS_GIT_REPO="hgi https://github.com/wtsi-hgi/arvados.git" -e ARVADOS_GIT_REV="hgi/master" -e ARVADOS_DEV_GIT_REPO="hgi https://github.com/wtsi-hgi/arvados-dev.git" -e ARVADOS_DEV_GIT_REV="hgi/master" local/docker-arvados-dev
 ```
 
 Note that there is also a trusted/automated build of this repository on [docker hub](https://hub.docker.com/r/mercury/docker-arvados-dev/), so you should be able to skip the `docker build` step above and replace `local/docker-arvados-dev` with `mercury/docker-arvados-dev` to run directly from docker hub's automated build. 

For example, to pull the Docker image from Docker hub and run all tests against the wtsi-hgi branch, you could do:
 ```bash
docker run -it --privileged -e ARVADOS_GIT_REPO="hgi https://github.com/wtsi-hgi/arvados.git" -e ARVADOS_GIT_REV="hgi/master" -e ARVADOS_DEV_GIT_REPO="hgi https://github.com/wtsi-hgi/arvados-dev.git" -e ARVADOS_DEV_GIT_REV="hgi/master" mercury/docker-arvados-dev
 ```
 
