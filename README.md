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
 docker run -it local/docker-arvados-dev
 ```
or, equivalently:
```bash
docker run -it local/docker-arvados-dev time ~/arvados-dev/jenkins/run-tests.sh WORKSPACE=~/arvados
```

To run all tests against the staging branch:
```bash
 docker run -it -e ARVADOS_DEV_REVISION=staging local/docker-arvados-dev
 ```
