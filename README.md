# Spark for Local Development

This repository contains Spark for local docker development

## Components
1. Apache Spark 3.4.1
    - Spark in Standalone Cluster Mode
    - Spark History Server
2. Apache Hadoop 3.3.6
3. Python 3.10.13 
4. Jupyter Lab

## Services in Docker
| Name | URL |
| ----- | ----- |
| Jupyter Lab | [http://localhost:8089](http://localhost:8089) |
| Spark Master | [http://localhost:8080](http://localhost:8080) |
| Spark History Server | [http://localhost:18080](http://localhost:18080) |
| Spark Web UI | [http://localhost:4040-4060](http://localhost:4040-4060) |

## How to Get Started
- build the docker
```
docker build -t spark-in-local:spark3.4.1-python3.10.13 \
    --build-arg python_version=3.10.13 \
    --build-arg spark_version=3.4.1 \
    --build-arg maven_version=3.9.4 \
    --build-arg hadoop_version=3.3.6 \
    .
```
- start the components
```
docker-compose up -d

# scale spark worker
docker-compose up -d --scale spark-worker=2
```

## How to run PySpark 
1. run through Jupyter Notebook (see [spark_nb.ipynb](./spark_nb.ipynb))
    - range of Spark Web UI port is `4051-4060`
2. run through spark-submit command through `spark-master` (see [spark_script.py](./spark_script.py))
    - execute `docker exec -it spark-master /bin/bash`
    - then do spark-submit `spark-submit --master spark://spark-master:7077 spark_script.py`
    - range of Spark Web UI port is `4040-4050`