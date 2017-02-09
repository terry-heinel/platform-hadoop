FROM openjdk:8-jdk

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ENV HADOOP_VERSION 2.7.3
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME $HADOOP_PREFIX
ENV HADOOP_HDFS_HOME $HADOOP_PREFIX
ENV HADOOP_MAPRED_HOME $HADOOP_PREFIX
ENV HADOOP_YARN_HOME $HADOOP_PREFIX

RUN apt-get update

# For production, you probably want to split the SSH server packages to a
# separate docker. They are required only for the yarn slave nodes.
RUN apt-get install -y ssh
RUN mkdir -p /var/run/sshd

# Hadoop
RUN wget -q -O - \
  http://mirrors.ocf.berkeley.edu/apache/hadoop/common/hadoop-2.7.3/hadoop-$HADOOP_VERSION.tar.gz \
  | tar -xzf - -C /usr/local
RUN ln -s /usr/local/hadoop-$HADOOP_VERSION $HADOOP_PREFIX

# Clean up
RUN apt-get clean && rm -rf /tmp/* /var/tmp/*

# SSH Key Set Up. Again, this should probably be an image just for the YARN
# slaves.
USER root
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

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

# HDFS
EXPOSE 50010 50020 50070 50075 50090 8020 9000

# MapReduce
EXPOSE 10020 19888

# YARN
EXPOSE 8030 8031 8032 8033 8040 8042 8088

# SSH
EXPOSE 22
