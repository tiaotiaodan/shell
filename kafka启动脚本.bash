#!/bin/sh
#
# chkconfig: 345 99 01
# description: Kafka
#
# File : Kafka
#
# Description: Starts and stops the Kafka server
#

source /etc/rc.d/init.d/functions

KAFKA_HOME=/app/opt/kafka_2.11-2.3.0/
KAFKA_USER=root
export LOG_DIR=/app/log/kafka

[ -e /etc/sysconfig/kafka ] && . /etc/sysconfig/kafka

# See how we were called.
case "$1" in

  start)
    echo -n "Starting Kafka:"
    /sbin/runuser -s /bin/sh $KAFKA_USER -c "nohup $KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties > $LOG_DIR/server.out 2> $LOG_DIR/server.err &"
    echo " done."
    exit 0
    ;;

  stop)
    echo -n "Stopping Kafka: "
    /sbin/runuser -s /bin/sh $KAFKA_USER  -c "ps -ef | grep kafka.Kafka | grep -v grep | awk '{print $2}' | xargs kill"
    echo " done."
    exit 0
    ;;
  hardstop)
    echo -n "Stopping (hard) Kafka: "
    /sbin/runuser -s /bin/sh $KAFKA_USER  -c "ps -ef | grep kafka.Kafka | grep -v grep | awk '{print $2}' | xargs kill -9"
    echo " done."
    exit 0
    ;;

  status)
    c_pid=`ps -ef | grep kafka.Kafka | grep -v grep | awk '{print $2}'`
    if [ "$c_pid" = "" ] ; then
      echo "Stopped"
      exit 3
    else
      echo "Running $c_pid"
      exit 0
    fi
    ;;

  restart)
    stop
    start
    ;;

  *)
    echo "Usage: kafka {start|stop|hardstop|status|restart}"
    exit 1
    ;;

esac