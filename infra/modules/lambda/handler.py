import os
from pyspark.context import SparkContext
from awsglue.context import GlueContext

def create_schemas_and_tables():
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session

    silver_bucket = os.environ.get("S3_BUCKET_SILVER", "coingecko-silver-663354324751")
    gold_bucket = os.environ.get("S3_BUCKET_GOLD", "coingecko-gold-663354324751")

    # Criar schemas (databases)
    spark.sql("CREATE DATABASE IF NOT EXISTS silver")
    spark.sql("CREATE DATABASE IF NOT EXISTS gold")

    # Criar tabela silver.coins
    spark.sql(f"""
        CREATE EXTERNAL TABLE IF NOT EXISTS silver.coins (
            id STRING,
            name STRING,
            symbol STRING,
            current_price DECIMAL(18,4),
            last_updated TIMESTAMP,
            anomesdia STRING
        )
        STORED AS PARQUET
        LOCATION 's3://{silver_bucket}/silver/coins/'
    """)

    # Criar tabela gold.coin_aggregates
    spark.sql(f"""
        CREATE EXTERNAL TABLE IF NOT EXISTS gold.coin_aggregates (
            id STRING,
            name STRING,
            symbol STRING,
            anomesdia STRING,
            avg_price_usd DECIMAL(18,4),
            min_price_usd DECIMAL(18,4),
            max_price_usd DECIMAL(18,4),
            records_count INT,
            last_updated TIMESTAMP
        )
        STORED AS PARQUET
        LOCATION 's3://{gold_bucket}/gold/coin_aggregates/'
    """)

if __name__ == "__main__":
    create_schemas_and_tables()
