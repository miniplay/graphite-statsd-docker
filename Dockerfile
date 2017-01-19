FROM centos:7
MAINTAINER Rafael de Elvira <rafa@minijuegos.com>


# Install EPEL & upgrade
RUN yum -y install epel-release

RUN yum -y update\
 && yum -y upgrade


# dependencies
RUN yum -y install vim\
 nginx\
 python-devel\
 python-flup\
 python-pip\
 python-ldap\
 expect\
 git\
 memcached\
 sqlite3\
 cairo\
 cairo-devel\
 python-cairo\
 pkg-config\
 nodejs\
 gcc\
 supervisor\
 net-tools\
 libffi-devel

# python dependencies
RUN pip install django==1.5.12\
 python-memcached==1.53\
 django-tagging==0.3.1\
 twisted==11.1.0\
 txAMQP==0.6.2\
 cffi\
 cairocffi

# install graphite
RUN git clone -b 0.9.15 --depth 1 https://github.com/graphite-project/graphite-web.git /usr/local/src/graphite-web
WORKDIR /usr/local/src/graphite-web
RUN python ./setup.py install
ADD conf/opt/graphite/conf/*.conf /opt/graphite/conf/
ADD conf/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py

# install whisper
RUN git clone -b 0.9.15 --depth 1 https://github.com/graphite-project/whisper.git /usr/local/src/whisper
WORKDIR /usr/local/src/whisper
RUN python ./setup.py install

# install carbon
RUN git clone -b 0.9.15 --depth 1 https://github.com/graphite-project/carbon.git /usr/local/src/carbon
WORKDIR /usr/local/src/carbon
RUN python ./setup.py install

# install statsd
RUN git clone -b v0.7.2 https://github.com/etsy/statsd.git /opt/statsd
ADD conf/opt/statsd/config.js /opt/statsd/config.js

# config nginx
#RUN rm /etc/nginx/sites-enabled/default
ADD conf/etc/nginx/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /etc/nginx/sites-enabled/
ADD conf/etc/nginx/sites-enabled/graphite-statsd.conf /etc/nginx/sites-enabled/graphite-statsd.conf

# logging support
RUN mkdir -p /var/log/carbon /var/log/graphite /var/log/nginx
#RUN mkdir -p /var/log/supervisord/nginx /var/log/supervisord/graphite /var/log/supervisord/carbon /var/log/supervisord/carbon-aggr /var/log/supervisord/statsd
ADD conf/etc/logrotate.d/graphite-statsd /etc/logrotate.d/graphite-statsd

# Setup Supervisor
ADD conf/etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# cleanup
RUN yum clean all\
 && rm -rf /tmp/* /var/tmp/*

# defaults
EXPOSE 80 2003-2004 2023-2024 8125/udp
#VOLUME ["/opt/graphite/conf", "/opt/graphite/storage", "/etc/nginx", "/opt/statsd", "/etc/logrotate.d", "/var/log"]
WORKDIR /
ENV HOME /root
CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
