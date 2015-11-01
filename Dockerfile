#name of container: docker-transmission
#versison of container: 0.5.3
FROM quantumobject/docker-baseimage:15.10
MAINTAINER Angel Rodriguez  "angel@quantumobject.com"

# Set correct environment variables.
ENV USER_T guest
ENV PASSWD_T guest

#add repository and update the container
#Installation of nesesary package/software for this containers...
RUN echo "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc)-backports main restricted universe" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y -q build-essential automake \
                    autoconf libtool pkg-config intltool libcurl4-openssl-dev \
                    libglib2.0-dev libevent-dev xz-utils\
                    libminiupnpc-dev libminiupnpc10 libappindicator-dev \
                    && wget http://download.transmissionbt.com/files/transmission-2.84.tar.xz \
                    && tar xvf transmission-2.84.tar.xz \
                    && rm transmission-2.84.tar.xz \
                    && cd transmission-2.84 \
                    && ./configure -q && make -s \
                    && make install \
                    && apt-get clean \
                    && rm -rf /tmp/* /var/tmp/*  \
                    && rm -rf /var/lib/apt/lists/*

##startup scripts  
#Pre-config scrip that maybe need to be run one time only when the container run the first time .. using a flag to don't 
#run it again ... use for conf for service ... when run the first time ...
RUN mkdir -p /etc/my_init.d
COPY startup.sh /etc/my_init.d/startup.sh
RUN chmod +x /etc/my_init.d/startup.sh

# to add transmissiond deamon to runit
RUN mkdir /etc/service/transmissiond
COPY transmissiond.sh /etc/service/transmissiond/run
RUN chmod +x /etc/service/transmissiond/run
COPY transmissionfd.sh /usr/bin/transmissionfd
RUN chmod +x /usr/bin/transmissionfd

#pre-config scritp for different service that need to be run when container image is create 
#maybe include additional software that need to be installed ... with some service running ... like example mysqld
COPY pre-conf.sh /sbin/pre-conf
RUN chmod +x /sbin/pre-conf \
    && /bin/bash -c /sbin/pre-conf \
    && rm /sbin/pre-conf

##scritp that can be running from the outside using docker-bash tool ...
## for example to create backup for database with convitation of VOLUME   dockers-bash container_ID backup_mysql
COPY backup.sh /sbin/backup
RUN chmod +x /sbin/backup
VOLUME /var/backups

#add files and script that need to be use for this container
#include conf file relate to service/daemon 
#additionsl tools to be use internally 
COPY settings.json /var/lib/transmission-daemon/info/settings.json

# to allow access from outside of the container  to the container service
# at that ports need to allow access from firewall if need to access it outside of the server. 
EXPOSE 9091

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
