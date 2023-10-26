FROM centos:7

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


# install spark
ARG spark_version=3.4.1
ARG spark_archive=spark-${spark_version}-bin-hadoop3
RUN echo "installing Spark version ${spark_version}"
RUN wget https://archive.apache.org/dist/spark/spark-${spark_version}/${spark_archive}.tgz &&\
    tar -xvf ${spark_archive}.tgz -C /opt && rm ${spark_archive}.tgz && \
    ln -s ${spark_archive} /opt/spark


# install maven
ARG maven_version=3.9.4
RUN wget https://dlcdn.apache.org/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz --no-check-certificate && \
    tar -xvf apache-maven-${maven_version}-bin.tar.gz -C /opt && rm apache-maven-${maven_version}-bin.tar.gz && \
    ln -s /opt/apache-maven-${maven_version} /opt/maven
    

ENV JAVA_HOME /usr/lib/jvm/jre-openjdk
ENV SPARK_HOME /opt/spark
ENV HADOOP_HOME /opt/spark
ENV PYTHONPATH /opt/spark/python
ENV PYSPARK_DRIVER_PYTHON=/usr/local/bin/python3

ENV PYSPARK_PYTHON python3
ENV M2_HOME /opt/maven
ENV MAVEN_HOME /opt/maven
ENV PATH ${SPARK_HOME}/bin:${M2_HOME}/bin:$PATH

COPY requirements.txt /home/
RUN pip3 install -r /home/requirements.txt

COPY ./script/start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /home