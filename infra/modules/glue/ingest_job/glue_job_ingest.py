import requests
import json
import logging
from datetime import datetime
from pyspark.sql import SparkSession
import boto3

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Spark session
spark = SparkSession.builder.appName("CoingeckoIngestion").getOrCreate()

# ===== GET API KEY FROM PARAMETER STORE =====
ssm = boto3.client('ssm', region_name='us-east-1')  # Altere a região se necessário

parameter = ssm.get_parameter(
    Name="/coing-gecko/api_key",
    WithDecryption=True
)
API_KEY = parameter['Parameter']['Value']

# ============================================
   
# Configuration
url = "https://api.coingecko.com/api/v3/coins/markets"
bucket_name = "coingecko-staging-663354324751"
 
# API request parameters 
params = {
    "x_cg_demo_api_key": API_KEY,
    "vs_currency": "usd",
    "sparkline": "true",
    "per_page": 150 
} 

# Make API request
logger.info("Calling CoinGecko API...")
resp = requests.get(url, params=params)

if resp.status_code == 200:
    data = resp.json()

    # Create Spark DataFrame from JSON response
    df = spark.read.json(spark.sparkContext.parallelize([json.dumps(data)]))

    # Format current date as YYYYMMDD
    now = datetime.utcnow().strftime("%Y%m%d")
    prefix = f"anomesdia={now}/"

    # Define S3 output path
    output_path = f"s3://{bucket_name}/raw/{prefix}"

    # Write to S3 in Parquet format
    df.write.mode("append").parquet(output_path)

    logger.info(f"Data successfully written to {output_path}")
else:
    logger.error(f"API Error {resp.status_code}: {resp.text}")