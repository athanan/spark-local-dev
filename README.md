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
docker build -t spark-in-local:latest \
    --build-arg python_version=3.10.13 \
    --build-arg spark_version=3.4.1 \
    --build-arg maven_version=3.9.4 \
    --build-arg hadoop_version=3.3.6 \
    --build-arg hive_version=3.1.3 \
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



CREATE DATABASE local_db LOCATION 's3a://spark-warehouse/local_db';

CREATE EXTERNAL TABLE local_db.test_table 
(`id` string, `f_anme` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY "\u003B" STORED AS TEXTFILE
LOCATION "s3a://spark-warehouse/local_db/test_table" 
TBLPROPERTIES("skip.header.line.count"="1");

INSERT INTO local_db.test_table VALUES ('A', 'B');

SELECT * FROM local_db.test_table;

spark-shell
import org.apache.spark.sql.SparkSession
val spark = SparkSession.builder().appName("Sname").enableHiveSupport().getOrCreate()
