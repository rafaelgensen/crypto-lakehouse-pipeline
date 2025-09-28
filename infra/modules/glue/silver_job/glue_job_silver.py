import logging
from datetime import datetime
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    lower,
    trim,
    current_timestamp,
    round as spark_round
)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Spark session
spark = SparkSession.builder.appName("CoingeckoBronzeToSilver").getOrCreate()

# =========================
# Configuration
# =========================
bucket_bronze = "coingecko-bronze-663354324751"
bucket_silver = "coingecko-silver-663354324751"
bronze_path = f"s3://{bucket_bronze}/bronze/" 
silver_path = f"s3://{bucket_silver}/silver/"

# =========================
# Read data from Bronze
# =========================
logger.info("Reading data from bronze layer...")
df_bronze = spark.read.parquet(bronze_path)
logger.info(f"Records read: {df_bronze.count()}")

# =========================
# Data Cleaning & Transformation
# =========================

# Basic normalization:
# - Remove nulls
# - Clean strings
# - Rename columns (if needed)
# - Round numeric columns
# - Add processing timestamp

required_columns = ["id", "name", "symbol", "current_price", "anomesdia"]

for col_name in required_columns:
    df_bronze = df_bronze.filter(col(col_name).isNotNull())

df_silver = df_bronze \
    .withColumn("id", lower(trim(col("id")))) \
    .withColumn("symbol", lower(trim(col("symbol")))) \
    .withColumn("name", trim(col("name"))) \
    .withColumn("current_price", spark_round(col("current_price"), 4)) \
    .withColumn("last_updated", current_timestamp())

# =========================
# Write to Silver
# =========================
logger.info("Writing data to silver layer...")

df_silver.write \
    .mode("append") \
    .partitionBy("anomesdia") \
    .parquet(silver_path)

logger.info(f"Data successfully written to {silver_path}")