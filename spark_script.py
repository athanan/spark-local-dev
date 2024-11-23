"""
spark-submit \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.6.1 \
    --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions \
    --conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkSessionCatalog \
    --conf spark.sql.catalog.spark_catalog.type=hive \
    spark_script.py
"""

from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("test").enableHiveSupport().getOrCreate()

df = spark.read.format('parquet').load("s3a://raw-data/")

print(f"row count: {df.count()}")
print(df.printSchema())

target_columns = ["VendorID", "lpep_pickup_datetime", "lpep_dropoff_datetime"]
df = df.select(target_columns)
df = df.limit(100)

hive_db = "local_db"
hive_table_name = "test_from_spark_submit"

print(f"create table {hive_db}.{hive_table_name}")
df.writeTo(f"{hive_db}.{hive_table_name}").using("iceberg").create()

print(spark.sql("SHOW CREATE TABLE local_db.test_from_spark_submit").collect()[0].createtab_stmt)

spark.sql("SELECT * FROM local_db.test_from_spark_submit LIMIT 10").show()