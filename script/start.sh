#!/usr/bin/env bash

echo "Run mode: $SPARK_RUN_MODE"

if [ "$SPARK_RUN_MODE" == "master" ];
then
    ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.master.Master

elif [ "$SPARK_RUN_MODE" == "worker" ];
then
    /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker $SPARK_MASTER_URL
elif [ "$SPARK_RUN_MODE" == "history" ];
then
    $SPARK_HOME/sbin/start-history-server.sh
   tail -f /dev/null
else
    echo "please specify SPARK_RUN_MODE (master / worker / history)"
    exit 1
fi
