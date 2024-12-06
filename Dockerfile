FROM python:3.12.7

RUN apt update -y
RUN apt install -y openjdk-17-jdk

################################################################################
# install spark
ARG spark_version=3.5.3
RUN echo "installing Spark version ${spark_version}"
RUN wget https://archive.apache.org/dist/spark/spark-${spark_version}/spark-${spark_version}-bin-without-hadoop.tgz && \
    tar -xvf spark-${spark_version}-bin-without-hadoop.tgz -C /opt && rm spark-${spark_version}-bin-without-hadoop.tgz && \
    ln -s spark-${spark_version}-bin-without-hadoop /opt/spark

################################################################################
# install hadoop
ARG hadoop_version=3.3.6
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz && \
    tar -xvf hadoop-${hadoop_version}.tar.gz -C /opt && rm hadoop-${hadoop_version}.tar.gz && \
    ln -s hadoop-${hadoop_version} /opt/hadoop

################################################################################
# install hive metastore
ARG hive_version=2.3.9
RUN wget https://archive.apache.org/dist/hive/hive-${hive_version}/apache-hive-${hive_version}-bin.tar.gz && \
    tar -xvf apache-hive-${hive_version}-bin.tar.gz -C /opt && rm apache-hive-${hive_version}-bin.tar.gz && \
    ln -s apache-hive-${hive_version}-bin /opt/hive

RUN wget -P /opt/hive/lib https://jdbc.postgresql.org/download/postgresql-42.6.0.jar --no-check-certificate

################################################################################
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-arm64
ENV SPARK_HOME /opt/spark
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_OPTIONAL_TOOLS="hadoop-aws"
ENV HIVE_HOME=/opt/hive
ENV SPARK_DIST_CLASSPATH=${HADOOP_HOME}/etc/hadoop:${HADOOP_HOME}/share/hadoop/common/lib/*:${HADOOP_HOME}/share/hadoop/common/*:${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-bundle-1.12.367.jar:${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-3.3.6.jar:${HADOOP_HOME}/share/hadoop/hdfs:${HADOOP_HOME}/share/hadoop/hdfs/lib/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/mapreduce/*:${HADOOP_HOME}/share/hadoop/yarn:${HADOOP_HOME}/share/hadoop/yarn/lib/*:${HADOOP_HOME}/share/hadoop/yarn/*
ENV HADOOP_CLIENT_OPTS="--add-opens java.base/java.net=ALL-UNNAMED $HADOOP_CLIENT_OPTS"
ENV PYTHONPATH /opt/spark/python
ENV PYSPARK_PYTHON=python3
ENV M2_HOME /opt/maven
ENV MAVEN_HOME /opt/maven
ENV PATH ${SPARK_HOME}/bin:${M2_HOME}/bin:${HADOOP_HOME}/bin:${HIVE_HOME}/bin:${JAVA_HOME}/bin:$PATH

################################################################################
# Add spark hive jar
RUN wget -P ${SPARK_HOME}/jars https://repo1.maven.org/maven2/org/apache/spark/spark-hive_2.12/${spark_version}/spark-hive_2.12-${spark_version}.jar
RUN ln -s ${HIVE_HOME}/lib/hive-* ${SPARK_HOME}/jars

################################################################################
# install python package
COPY requirements.txt /home/
RUN pip install -r /home/requirements.txt

################################################################################
COPY conf/hadoop/core-site.xml ${HADOOP_HOME}/etc/hadoop/core-site.xml
COPY conf/hadoop/core-site.xml ${SPARK_HOME}/etc/hadoop/core-site.xml
COPY conf/hive/hive-site.xml ${SPARK_HOME}/conf/hive-site.xml
COPY conf/spark/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf
COPY conf/hive/hive-site.xml ${HIVE_HOME}/conf/hive-site.xml

COPY ./script/start.sh /start.sh
COPY ./script/start-metastore.sh /start-metastore.sh
RUN chmod +x /start.sh /start-metastore.sh

# disable spark's log 
RUN ipython profile create && \
    echo "c.IPKernelApp.capture_fd_output = False" >> "/root/.ipython/profile_default/ipython_kernel_config.py"

WORKDIR /home
