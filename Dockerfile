# Creates a base distributed Hadoop cluster ( YARN / HDFS / MapReduce)
# To build the image run the following command from the directory containing
# this file.
#     "sudo docker build -t risksense/platform-hadoop ."

# This image can be used to create any of the HDFS or YARN node types.
# Further tweaking may be needed for optimal configuration of specific nodes.

FROM openjdk:8-jdk

USER root

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ENV HADOOP_VERSION 2.7.3
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME $HADOOP_PREFIX
ENV HADOOP_HDFS_HOME $HADOOP_PREFIX
ENV HADOOP_MAPRED_HOME $HADOOP_PREFIX
ENV HADOOP_YARN_HOME $HADOOP_PREFIX

RUN apt-get update

# SSH server
RUN apt-get install -y ssh
RUN mkdir -p /var/run/sshd

# Hadoop
RUN wget -q -O - \
  http://mirrors.ocf.berkeley.edu/apache/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz \
  | tar -xzf - -C /usr/local
RUN ln -s /usr/local/hadoop-$HADOOP_VERSION $HADOOP_PREFIX

# Clean up
RUN apt-get clean && rm -rf /tmp/* /var/tmp/*

# Add configuration files
# All nodes (master and worker) need these files
ADD conf/datanode/etc/hadoop/core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD conf/datanode/etc/hadoop/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD conf/datanode/etc/hadoop/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD conf/datanode/etc/hadoop/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

# Only master nodes need these but it's okay to put them on all nodes
# the "masters" file is used for specifying the secondary namenode host address
ADD conf/namenode/etc/hadoop/capacity-scheduler.xml $HADOOP_PREFIX/etc/hadoop/capacity-scheduler.xml
ADD conf/namenode/etc/hadoop/slaves $HADOOP_PREFIX/etc/hadoop/slaves
ADD conf/namenode/etc/hadoop/masters $HADOOP_PREFIX/etc/hadoop/masters

# Log configuration files
ADD conf/logging/log4j.properties $HADOOP_PREFIX/etc/hadoop/log4j.properties
ADD conf/logging/log4j-cli.properties $HADOOP_PREFIX/etc/hadoop/log4j-cli.properties
ADD conf/logging/log4j-yarn-session.properties $HADOOP_PREFIX/etc/hadoop/log4j-yarn-session.properties

# SSH Key Set Up.
RUN yes | ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN yes | ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN yes | ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

ADD ssh_environment /root/.ssh/environment
RUN chmod 600 /root/.ssh/environment
RUN chown root:root /root/.ssh/environment
RUN echo 'PermitUserEnvironment yes' >> /etc/ssh/sshd_config

# Bootstrap configuration
ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

# YARN
EXPOSE 8030 8031 8032 8033 8040 8042 8088 45454

# MapReduce
EXPOSE 10020 19888

# HDFS
EXPOSE 50010 50020 50070 50075 50090 8020 9000 9864

# SSH
EXPOSE 22
