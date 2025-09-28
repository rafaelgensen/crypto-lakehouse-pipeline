import logging
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    avg,
    max as spark_max,
    min as spark_min,
    count,
    current_timestamp
)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__) 

# Initialize Spark session
spark = SparkSession.builder.appName("CoingeckoSilverToGold").getOrCreate()  

# =========================
# Configuration
# =========================
bucket_silver = "coingecko-silver-663354324751"
bucket_gold   = "coingecko-gold-663354324751"

silver_path = f"s3://{bucket_silver}/silver/"
gold_path   = f"s3://{bucket_gold}/gold/"

# =========================
# Read from Silver
# =========================
logger.info("Reading data from silver layer...")
df_silver = spark.read.parquet(silver_path)

logger.info(f"Records read from silver: {df_silver.count()}")

# =========================
# Aggregation for Gold
# =========================

# Example 1: Average price per coin across the day
# Example 2: Price range (min/max)
# Example 3: Count of appearances

df_gold = df_silver.groupBy("id", "name", "symbol", "anomesdia").agg(
    avg("current_price").alias("avg_price_usd"),
    spark_min("current_price").alias("min_price_usd"),
    spark_max("current_price").alias("max_price_usd"),
    count("*").alias("records_count")
).withColumn("last_updated", current_timestamp())

# =========================
# Write to Gold
# =========================

logger.info("Writing aggregated data to gold layer...")

df_gold.write \
    .mode("append") \
    .partitionBy("anomesdia") \
    .parquet(gold_path)

logger.info(f"Data successfully written to {gold_path}")
