"""
spark-submit \
    --master spark://spark-master:7077 \
    spark_script.py
"""

import requests
from pathlib import Path
from pyspark.sql import SparkSession

url = 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet'
data_dir = '/home/data/nyc_taxi_data/yellow_tripdata'
Path("data_dir").mkdir(parents=True, exist_ok=True)

print(f"downloading dataset from {url}")
r = requests.get(url)  
with open(data_dir, 'wb') as f:
    f.write(r.content)

spark = SparkSession.builder.appName('test').getOrCreate()

df = spark.read.format('parquet').load(data_dir)

print(f"row count: {df.count()}")
print(df.printSchema())