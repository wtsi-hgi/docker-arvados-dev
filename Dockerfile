FROM debian:jessie
MAINTAINER jcrandall@alum.mit.edu

# Update core packages and install apt-utils
RUN \
  apt-get -q=2 update && \
  apt-get -q=2 upgrade

# Create arvados user with sudo access
RUN \
  apt-get -q=2 install -y sudo && \
  adduser --disabled-password --gecos "" -q arvados && \
  adduser arvados sudo && \
  echo "%sudo ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopasswd
USER arvados
WORKDIR /home/arvados

# Install Arvados prerequisite debian packages
RUN sudo apt-get -q=2 -y install \
	 bison \
	 build-essential \
	 curl \
	 fuse \
	 gem \
	 gettext \
	 git \
	 golang=2:1.3.3-1 \
	 graphviz \
	 iceweasel \
	 libattr1-dev \
	 libfuse-dev \
	 libcrypt-ssleay-perl \
	 libcurl3 \
	 libcurl3-gnutls \
	 libcurl4-openssl-dev \
	 libjson-perl \
	 libpcre3-dev \
	 libpq-dev \
	 libpython2.7-dev \
	 libreadline-dev \
	 libssl-dev \
	 libxslt1.1 \
	 libwww-perl \
	 linkchecker \
	 lsof \
	 nginx \
	 perl \ 
	 perl-modules \
	 postgresql \
	 python \
	 pkg-config \
	 ruby2.1 \
	 ruby2.1-dev \
	 sudo \
	 virtualenv \
	 wget \
	 xvfb \
	 zlib1g-dev \
    && \
    sudo apt-get -q=2 -y --no-install-recommends install \
	 python-epydoc \
    && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get -q=2 -y --no-install-recommends install \
	 gitolite3

# Install phantomjs 1.9.8
ENV PJS phantomjs-1.9.8-linux-x86_64
RUN \
    cd /tmp && \
    curl -LO https://bitbucket.org/ariya/phantomjs/downloads/$PJS.tar.bz2 && \
    ( echo "4ea7aa79e45fbc487a63ef4788a18ef7  /tmp/$PJS.tar.bz2" | md5sum -c ) && \
    sudo tar -C /usr/local -xjf /tmp/$PJS.tar.bz2 && \
    sudo ln -s ../$PJS/bin/phantomjs /usr/local/bin/

# Install new versions of pip and setuptools
RUN \
    ( wget https://bootstrap.pypa.io/ez_setup.py -O - | sudo python ) && \
    ( wget https://bootstrap.pypa.io/get-pip.py -O - | sudo python )

# Setup git config
RUN git config --global push.default matching

# Clone Arvados source into ~arvados/
RUN git clone https://github.com/curoverse/arvados.git
RUN git clone https://github.com/curoverse/arvados-dev.git

# Create fuse and docker groups
RUN \
    sudo addgroup fuse && \
    sudo adduser arvados fuse && \
    sudo addgroup docker && \
    sudo adduser arvados docker

# Configure postgres
RUN (tr -cd a-zA-Z < /dev/urandom | head -c32 > ~/arvados.pgpass ) && \
    sudo /etc/init.d/postgresql start && \
    sudo -u postgres psql -c "create user arvados with createdb encrypted password '$(cat ~/arvados.pgpass)'" && \
    cp ~/arvados/services/api/config/database.yml.example ~/arvados/services/api/config/database.yml && \
    newpw="$(cat ~/arvados.pgpass)" perl -pi~ -e 's/xxxxxxxx/$ENV{newpw}/' ~/arvados/services/api/config/database.yml

# Configure Arvados application.yml
RUN cp ~/arvados/services/api/config/application.yml.example ~/arvados/services/api/config/application.yml

# Configure GOPATH to use Go source from git checkout
ENV GOPATH /home/arvados/gocode
RUN mkdir -p ${GOPATH}/src/git.curoverse.com && ln -s ~/arvados ${GOPATH}/src/git.curoverse.com/arvados.git

# Add links to make ruby2.1 the default
RUN \
    sudo ln -s /usr/bin/ruby2.1 /usr/local/bin/ruby && \
    sudo ln -s /usr/bin/erb2.1 /usr/local/bin/erb && \
    sudo ln -s /usr/bin/gem2.1 /usr/local/bin/gem && \
    sudo ln -s /usr/bin/irb2.1 /usr/local/bin/irb && \
    sudo ln -s /usr/bin/rake2.1 /usr/local/bin/rake && \
    sudo ln -s /usr/bin/rdoc2.1 /usr/local/bin/rdoc && \
    sudo ln -s /usr/bin/ri2.1 /usr/local/bin/ri && \
    sudo ln -s /usr/bin/testrb2.1 /usr/local/bin/testrb

# Make sure nginx logs and libs are writable
RUN \
    sudo rm -r /var/log/nginx && \
    mkdir ~/nginx.log && \
    sudo ln -s ~/nginx.log /var/log/nginx && \
    sudo rm -r /var/lib/nginx && \
    mkdir ~/nginx.lib && \
    sudo ln -s ~/nginx.lib /var/lib/nginx

# Add entrypoint from docker-arvados-dev git repo
ADD entrypoint.sh /docker/entrypoint.sh

# Default revision to checkout
ENV ARVADOS_DEV_REVISION master

# Set entrypoint to start postgres, pull from git repos, checkout ARVADOS_DEV_REVISION and then run whatever CMD is requested
ENTRYPOINT ["/docker/entrypoint.sh"]

# Set default command to git pull the latest arvados and arvados-dev, then 
# run all tests against the ~/arvados workspace
CMD ["time ~/arvados-dev/jenkins/run-tests.sh WORKSPACE=~/arvados"]
