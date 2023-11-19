"""
spark-submit \
    --master spark://spark-master:7077 \
    --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.4.2 \
    --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
    --conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkSessionCatalog \
    --conf spark.sql.catalog.spark_catalog.type=hive \
    spark_script.py
"""

def download_nyc_taxi_yellow_trip(data_dir):
    import requests
    from pathlib import Path

    url = 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet'
    Path(data_dir).mkdir(parents=True, exist_ok=True)

    print(f"downloading dataset from {url}")
    r = requests.get(url)  
    with open(f"{data_dir}/yellow_tripdata_2023-01.parquet", 'wb') as f:
        f.write(r.content)

from pyspark.sql import SparkSession
spark = SparkSession.builder.appName('test').enableHiveSupport().getOrCreate()

data_dir = '/home/data/nyc_taxi_data/yellow_tripdata/'
download_nyc_taxi_yellow_trip(data_dir)
df = spark.read.format('parquet').load(data_dir)

print(f"row count: {df.count()}")
print(df.printSchema())

# write raw data to s3
df.limit(1000).write.format('parquet').mode('overwrite').save('s3a://spark-warehouse/raw_data/save_from_spark_script')


# create new Spark table, register table metadata on Hive, and store data in s3
hive_db = 'local_db'
hive_table_name = 'test_hive_table'

print(f"create table {hive_db}.{hive_table_name}")
df.limit(1000).write.format('parquet').saveAsTable(f'{hive_db}.{hive_table_name}')

createtab_stmt = spark.sql(f'SHOW CREATE TABLE {hive_db}.{hive_table_name}').collect()[0]['createtab_stmt']
print(createtab_stmt)
spark.sql(f'SELECT * FROM {hive_db}.{hive_table_name} LIMIT 100').show(truncate=False)
spark.sql(f'DROP TABLE {hive_db}.{hive_table_name}')


# create new Iceberg table, register table pointer in Hive, and store data in s3
hive_table_name = 'test_iceberg_table'

print(f"create table {hive_db}.{hive_table_name}")
df.limit(1000).writeTo(f'{hive_db}.{hive_table_name}').using('iceberg').create()
createtab_stmt = spark.sql(f'SHOW CREATE TABLE {hive_db}.{hive_table_name}').collect()[0]['createtab_stmt']
print(createtab_stmt)
spark.sql(f'SELECT * FROM {hive_db}.{hive_table_name} LIMIT 100').show(truncate=False)
spark.sql(f'DROP TABLE {hive_db}.{hive_table_name} PURGE')
