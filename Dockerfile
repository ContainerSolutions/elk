FROM debian:jessie

MAINTAINER Container Solutions <info@container-solutions.com>

ENV DEBIAN_FRONTEND noninteractive

# Locales

RUN echo LANGUAGE=en_US.UTF-8 >> /etc/default/locale && \
    echo LC_ALL=en_US.UTF-8 >> /etc/default/locale && \
    echo LANGUAGE=en_US.UTF-8 > /etc/environment

# Common

RUN apt-get update && \ 
    apt-get install -y nginx curl software-properties-common unzip wget

# Java

ENV JAVA_VERSION 7u71
RUN apt-get update && apt-get install -y openjdk-7-jre-headless="$JAVA_VERSION"*
RUN update-alternatives --display java 
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

# Elasticsearch

ENV ES_VERSION 1.3.4
RUN curl -Ls https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${ES_VERSION}.tar.gz | \
    tar xz -C /opt && \
    ln -s elasticsearch-${ES_VERSION} /opt/elasticsearch
RUN mkdir -p /etc/service/elasticsearch && \
    mv /opt/elasticsearch/config/elasticsearch.yml /opt/elasticsearch/config/elasticsearch.yml.orig
ADD elasticsearch/config /opt/elasticsearch/config
RUN mkdir /elasticsearch
VOLUME ["/elasticsearch"]
EXPOSE 9200 9300

# Logstash

ENV LOGSTASH_VERSION 1.4.2
RUN curl -Ls https://download.elasticsearch.org/logstash/logstash/logstash-${LOGSTASH_VERSION}.tar.gz | \
    tar xz -C /opt && \
    ln -s logstash-${LOGSTASH_VERSION} /opt/logstash && \
    mkdir -p /etc/service/logstash
ADD logstash/config/logstash.conf /opt/logstash/config/logstash.conf
EXPOSE 5000 5000/udp

# Kibana

ENV KIBANA_VERSION 3.1.1
RUN curl -Ls https://download.elasticsearch.org/kibana/kibana/kibana-${KIBANA_VERSION}.tar.gz | \
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
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
