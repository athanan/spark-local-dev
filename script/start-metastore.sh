#!/bin/sh

export HADOOP_CLASSPATH=${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.563.jar:${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-3.3.0.jar

# Check if schema exists
${HIVE_HOME}/bin/schematool -dbType postgres -info
if ${HIVE_HOME}/bin/schematool -dbType postgres -validate | grep 'Done with metastore validation' | grep '[SUCCESS]'; then
  echo 'database is already initialized'
else
  ${HIVE_HOME}/bin/schematool -initSchema -dbType postgres 
fi

${HIVE_HOME}/bin/hive --service metastore
