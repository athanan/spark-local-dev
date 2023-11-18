FROM centos:7 AS python3

RUN yum install -y -q java-1.8.0-openjdk-devel gcc zlib-devel bzip2-devel readline-devel \
    epel-release sqlite-devel openssl-devel git libffi-devel wget
RUN yum install -y openssl11 openssl11-devel
RUN yum groupinstall "Development Tools" -y 
RUN yum clean all

# install sbt
RUN rm -f /etc/yum.repos.d/bintray-rpm.repo || true && \
    curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo && \
    mv sbt-rpm.repo /etc/yum.repos.d/ && \
    yum install -y sbt

# install maven
ARG maven_version=3.9.4
RUN wget https://dlcdn.apache.org/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz --no-check-certificate && \
    tar -xvf apache-maven-${maven_version}-bin.tar.gz -C /opt && rm apache-maven-${maven_version}-bin.tar.gz && \
    ln -s /opt/apache-maven-${maven_version} /opt/maven


# install python
ARG python_version
RUN echo "installing Python version ${python_version}"
RUN wget -q https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz && \
    tar -xf Python-${python_version}.tgz && rm Python-${python_version}.tgz && \
    cd Python-${python_version} && \
    export CFLAGS=$(pkg-config --cflags openssl11) && \
    export LDFLAGS=$(pkg-config --libs openssl11) && \
    ./configure --enable-optimizations --enable-loadable-sqlite-extensions -q && \
    make altinstall && \
    cd ../ && rm -rf Python-${python_version}

RUN ln -fs /usr/local/bin/python3.10 /usr/local/bin/python3 && \
    ln -fs /usr/local/bin/pip3.10 /usr/local/bin/pip3

RUN pip3 install --upgrade pip

################################################################################

FROM python3 AS spark-hive-hadoop

# install spark
ARG SPARK_VERSION=3.4.1
RUN echo "installing Spark version ${spark_version}"
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-without-hadoop.tgz && \
    tar -xvf spark-${SPARK_VERSION}-bin-without-hadoop.tgz -C /opt && rm spark-${SPARK_VERSION}-bin-without-hadoop.tgz && \
    ln -s spark-${SPARK_VERSION}-bin-without-hadoop /opt/spark

# install hadoop
ARG HADOOP_VERSION=3.3.6
RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xvf hadoop-${HADOOP_VERSION}.tar.gz -C /opt && rm hadoop-${HADOOP_VERSION}.tar.gz && \
    ln -s hadoop-${HADOOP_VERSION} /opt/hadoop

# install hive metastore
ARG HIVE_VERSION=3.1.3
RUN wget https://downloads.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    tar -xvf apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt && rm apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    ln -s apache-hive-${HIVE_VERSION}-bin /opt/hive

RUN wget -P /opt/hive/lib https://jdbc.postgresql.org/download/postgresql-42.6.0.jar --no-check-certificate

FROM spark-hive-hadoop

COPY requirements.txt /home/
RUN pip3 install -r /home/requirements.txt

ENV JAVA_HOME /usr/lib/jvm/jre-openjdk
ENV SPARK_HOME /opt/spark
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_OPTIONAL_TOOLS="hadoop-aws"
ENV HIVE_HOME=/opt/hive
ENV SPARK_DIST_CLASSPATH=${HADOOP_HOME}/etc/hadoop:${HADOOP_HOME}/share/hadoop/common/lib/*:${HADOOP_HOME}/share/hadoop/common/*:${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-bundle-1.12.367.jar:${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-3.3.6.jar:${HADOOP_HOME}/share/hadoop/hdfs:${HADOOP_HOME}/share/hadoop/hdfs/lib/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/mapreduce/*:${HADOOP_HOME}/share/hadoop/yarn:${HADOOP_HOME}/share/hadoop/yarn/lib/*:${HADOOP_HOME}/share/hadoop/yarn/*
ENV PYTHONPATH /opt/spark/python
ENV PYSPARK_PYTHON=python3
ENV M2_HOME /opt/maven
ENV MAVEN_HOME /opt/maven
ENV PATH ${SPARK_HOME}/bin:${M2_HOME}/bin:${HADOOP_HOME}/bin:${HIVE_HOME}/bin:$PATH

# fix hive dependency https://issues.apache.org/jira/browse/HIVE-22915
RUN rm ${HIVE_HOME}/lib/guava-19.0.jar && \
    cp ${HADOOP_HOME}/share/hadoop/hdfs/lib/guava-27.0-jre.jar ${HIVE_HOME}/lib/

# Add Spark Hive
RUN wget https://repo1.maven.org/maven2/org/apache/spark/spark-hive_2.12/3.4.1/spark-hive_2.12-3.4.1.jar && \
    mv spark-hive_2.12-3.4.1.jar ${SPARK_HOME}/jars

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