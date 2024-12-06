#!/bin/sh

mkdir -p data/nyc_taxi_data/
cd data/nyc_taxi_data/
wget https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2024-01.parquet
wget https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2024-02.parquet
wget https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2024-03.parquet
