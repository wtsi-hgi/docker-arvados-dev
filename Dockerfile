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

# Install prerequisite debian packages
RUN sudo apt-get -q=2 install -y \
           	                 bison \
	   			 build-essential \
				 fuse \
				 gettext \
				 git \
				 golang=2:1.3.3-1 \
				 graphviz \
				 iceweasel \
				 libattr1-dev \
				 libfuse-dev \
				 libcrypt-ssleay-perl \
				 libjson-perl \
				 libcurl3 \
				 libcurl3-gnutls \
				 libcurl4-openssl-dev \
				 libpcre3-dev \
				 libpq-dev \
				 libpython2.7-dev \
				 libreadline-dev \
				 libssl-dev \
				 libxslt1.1 \
				 linkchecker \
				 nginx \
				 perl-modules \
				 postgresql \
				 python \
				 python-epydoc \
				 pkg-config \
				 sudo \
				 virtualenv \
				 wget \
				 xvfb \
				 zlib1g-dev

# Install Ruby 2.1.6 from source
RUN \
    mkdir -p ~/src && \
    ( wget -q -O - http://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.6.tar.gz | tar xz ) && \
    cd ruby-2.1.6 && \
    ( ./configure --disable-install-rdoc && make && sudo make install ) > ~/src/ruby-2.1.6-configure-make-install.log

# Install phantomjs 1.9.8 
ENV PJS phantomjs-1.9.8-linux-x86_64
RUN \
    wget -q -P /tmp https://bitbucket.org/ariya/phantomjs/downloads/$PJS.tar.bz2 && \
    ( echo "4ea7aa79e45fbc487a63ef4788a18ef7  /tmp/$PJS.tar.bz2" | md5sum -c ) && \
    sudo tar -C /usr/local -xjf /tmp/$PJS.tar.bz2 && \
    sudo ln -s ../$PJS/bin/phantomjs /usr/local/bin/

# Clone Arvados source into ~arvados/
RUN git clone https://github.com/curoverse/arvados.git
RUN git clone https://github.com/curoverse/arvados-dev.git

# Create fuse group to allow arvados to write to /dev/fuse
# N.B. container may require `docker run --privileged` in order to actually mount fuse
RUN \
    sudo addgroup fuse && \
    sudo adduser arvados fuse && \
    sudo chown root:fuse /dev/fuse && \
    sudo chmod g+rw /dev/fuse

# Configure postgres
RUN (tr -cd a-zA-Z < /dev/urandom | head -c32 > ~/arvados.pgpass ) && \
    sudo /etc/init.d/postgresql start && \
    sudo -u postgres psql -c "create user arvados with createdb encrypted password '$(cat ~/arvados.pgpass)'" && \
    cp ~/arvados/services/api/config/database.yml.example ~/arvados/services/api/config/database.yml && \
    newpw="$(cat ~/arvados.pgpass)" perl -pi~ -e 's/xxxxxxxx/$ENV{newpw}/' ~/arvados/services/api/config/database.yml

# Configure Arvados application.yml
RUN cp ~/arvados/services/api/config/application.yml.example ~/arvados/services/api/config/application.yml

# Configure GOPATH to use Go source from git checkout
ENV GOPATH ~/gocode
RUN mkdir -p ${GOPATH}/src/git.curoverse.com && ln -s ~/arvados ${GOPATH}/src/git.curoverse.com/arvados.git

# Install gitolite3
RUN sudo DEBIAN_FRONTEND=noninteractive apt-get -q=2 install -y gitolite3 lsof

ADD entrypoint.sh /docker/entrypoint.sh

# Default revision to checkout
ENV ARVADOS_DEV_REVISION master

# Set entrypoint to start postgres, pull from git repos, checkout ARVADOS_DEV_REVISION and then run whatever CMD is requested
ENTRYPOINT ["/docker/entrypoint.sh"]

# Set default command to git pull the latest arvados and arvados-dev, then 
# run all tests against the ~/arvados workspace
CMD ["cd ~/arvados && \
     git pull && \
     cd ~/arvados-dev && \
     git pull && \
     cd ~ && \
     time ~/arvados-dev/jenkins/run-tests.sh WORKSPACE=~/arvados"]
