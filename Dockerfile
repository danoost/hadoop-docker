
FROM fedora:26
ARG HADOOP_VERSION=2.8.1

RUN dnf install -y curl which tar
RUN dnf install -y java-1.8.0-openjdk

RUN dnf install -y procps-ng hostname
RUN dnf install -y net-tools
# Aditional dependencies
RUN dnf install -y wget
RUN dnf install -y maven

ENV JAVA_HOME /usr/lib/jvm/jre

# Hadoop

# Download requested version
ARG HADOOP_HASH
ENV HADOOP_VERSION ${HADOOP_VERSION:-2.8.1}
ENV HADOOP_HASH ${HADOOP_HASH:-48d7fba961d5e0636228c5d45ec75d6bb0657b19}

# Download from Apache mirrors instead of archive #9
ENV APACHE_DIST_URLS \
  https://www.apache.org/dyn/closer.cgi?action=download&filename= \
# if the version is outdated (or we're grabbing the .asc file), we might have to pull from the dist/archive :/
  https://www-us.apache.org/dist/ \
  https://www.apache.org/dist/ \
https://archive.apache.org/dist/

RUN set -eux; \
  download_bin() { \
    local f="$1"; shift; \
    local hash="$1"; shift; \
    local distFile="$1"; shift; \
    local success=; \
    local distUrl=; \
    for distUrl in $APACHE_DIST_URLS; do \
      if wget -nv -O "$f" "$distUrl$distFile"; then \
        success=1; \
        # Checksum the download
        echo "$hash" "*$f" | sha1sum -c -; \
        break; \
      fi; \
    done; \
    [ -n "$success" ]; \
  };\
   \
   download_bin "hadoop.tar.gz" "$HADOOP_HASH" "hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" 

RUN tar xzf hadoop.tar.gz -C /tmp/
RUN rm hadoop.tar.gz 
RUN mv /tmp/hadoop-$HADOOP_VERSION /usr/local/hadoop-$HADOOP_VERSION

# hadoop
# ADD hadoop-${HADOOP_VERSION}.tar.gz /usr/local/
RUN ln -s /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/jre\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

# Hadoop config
ADD core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

ADD start-hadoop /start-hadoop
RUN chown root:root /start-hadoop
RUN chmod 700 /start-hadoop

ENV PATH "$PATH:$HADOOP_PREFIX/bin"

CMD /start-hadoop; while true; do sleep 10000; done

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000

# Mapred ports
EXPOSE 19888

# Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088

# Other ports
EXPOSE 49707 2122

