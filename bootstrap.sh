#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

# YARN binds ports on IPV6 by default. We want IPV4.
export HADOOP_OPTS="$HADOOP_OPTS -Djava.net.preferIPV4Stack=true"
export YARN_OPTS="$YARN_OPTS -Djava.net.preferIPV4Stack=true"

service ssh start
if [[ "$2" == "-namenode" ]]; then
  
  . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
  
  echo "Hadoop namenode startup."
  
  if [[ ! -f "$HADOOP_PREFIX/data/namenode/current/VERSION" ]]; then
    echo "Namenode needs formatting, running $HADOOP_PREFIX/bin/hdfs namenode -format"
    $HADOOP_PREFIX/bin/hdfs namenode -format
  else
    echo "Hadoop namenode already formatted"
  fi
  
  $HADOOP_PREFIX/sbin/start-dfs.sh
  $HADOOP_PREFIX/sbin/start-yarn.sh
fi

if [[ "$2" == "-datanode" ]]; then
  echo "Hadoop datanode startup."
fi

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
