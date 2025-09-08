import sys
import logging
from datetime import datetime
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, current_timestamp

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Spark Session
spark = SparkSession.builder.appName("CoingeckoBronzeJob").getOrCreate()

# ========================
# Configurations
# ========================
bucket_staging = "coingecko-staging-663354324751"
bucket_bronze = "coingecko-bronze-663354324751"
staging_path = f"s3://{bucket_staging}/raw/"
bronze_path = f"s3://{bucket_bronze}/bronze/"

# ========================
# Read data from staging bucket
# ========================

logger.info("Reading data from staging bucket...")
df_raw = spark.read.parquet(staging_path)

logger.info(f"Number of records read: {df_raw.count()}")

# ========================
# Data validation and cleansing
# ========================

# Ensure required fields are not null
required_columns = ["id", "name", "symbol", "current_price"]

for col_name in required_columns:
    df_raw = df_raw.filter(col(col_name).isNotNull())

# Remove duplicates based on coin id and ingestion date
df_clean = df_raw.dropDuplicates(["id", "anomesdia"])

# Add processing timestamp
df_clean = df_clean.withColumn("data_processamento", current_timestamp())

# ========================
# Write data to bronze bucket
# ========================

logger.info("Writing cleansed data to bronze bucket...")
df_clean.write \
    .mode("append") \
    .partitionBy("anomesdia") \
    .parquet(bronze_path)

logger.info(f"Data successfully written to {bronze_path}")