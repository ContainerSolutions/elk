FROM debian:jessie

MAINTAINER Container Solutions <info@container-solutions.com>

ENV DEBIAN_FRONTEND noninteractive

# Locales

RUN echo LANGUAGE=en_US.UTF-8 >> /etc/default/locale && \
    echo LC_ALL=en_US.UTF-8 >> /etc/default/locale && \
    echo LANGUAGE=en_US.UTF-8 > /etc/environment

# Java

ENV JAVA_VERSION 7u71
RUN apt-get update && apt-get install -y apt-utils curl wget openjdk-7-jre-headless="$JAVA_VERSION"*
RUN update-alternatives --display java 
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

# Elasticsearch & Logstash

ENV ES_VERSION 1.3
ENV LOGSTASH_VERSION 1.4
RUN wget -qO - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add - && \
    echo "\ndeb http://packages.elasticsearch.org/elasticsearch/${ES_VERSION}/debian stable main" >> /etc/apt/sources.list && \
    echo "\ndeb http://packages.elasticsearch.org/logstash/${LOGSTASH_VERSION}/debian stable main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install elasticsearch logstash
RUN mkdir /elasticsearch && \
    mv /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.orig
ADD elasticsearch/config /etc/elasticsearch
ADD logstash/config /etc/logstash/conf.d
VOLUME ["/elasticsearch"]
EXPOSE 9200 9300 5000 5000/udp

# Kibana & Nginx

ENV KIBANA_VERSION 3.1.1
RUN apt-get install -y nginx && \
    curl -Ls https://download.elasticsearch.org/kibana/kibana/kibana-${KIBANA_VERSION}.tar.gz | \
    tar xz -C /opt && \
    ln -s kibana-${KIBANA_VERSION} /opt/kibana
ADD https://raw.githubusercontent.com/elasticsearch/kibana/v${KIBANA_VERSION}/sample/nginx.conf /etc/nginx/sites-available/default
RUN sed -i -e 's%root.*%root /opt/kibana;%' /etc/nginx/sites-available/default && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
    sed -i -e 's%"http://"+window.location.hostname+":9200"%""%' /opt/kibana/config.js
EXPOSE 80

# Supervisor

RUN apt-get install -y supervisor
ADD supervisor/config/supervisor.conf /etc/supervisor/conf.d/elk.conf

# Clean Up

RUN apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache}/* /tmp/* /var/tmp/*

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
