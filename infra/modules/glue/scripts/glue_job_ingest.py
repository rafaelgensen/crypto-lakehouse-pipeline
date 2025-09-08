import requests
import json
from datetime import datetime
from pyspark.sql import SparkSession

# Spark session
spark = SparkSession.builder.appName("CoingeckoIngestion").getOrCreate()

# Configs
API_KEY = "CG-HvcvJstvuHKYZCRHafKrWgtd"
url = "https://api.coingecko.com/api/v3/coins/markets"
bucket_name = "coingecko-staging-663354324751"

# Chamada API
params = {
    "x_cg_demo_api_key": API_KEY,
    "vs_currency": "usd",
    "sparkline": "true",
    "per_page": 150
}
resp = requests.get(url, params=params)

if resp.status_code == 200:
    data = resp.json()

    # Cria DataFrame
    df = spark.read.json(spark.sparkContext.parallelize([json.dumps(data)]))

    # Data no formato YYYYMMDD
    now = datetime.utcnow().strftime("%Y%m%d")
    prefix = f"anomesdia={now}/"

    # Caminho final
    output_path = f"s3://{bucket_name}/raw/{prefix}"

    # Escreve em Parquet
    df.write.mode("append").parquet(output_path)

    print(f"Dados salvos em {output_path}")
else:
    print(f"Erro {resp.status_code}: {resp.text}")