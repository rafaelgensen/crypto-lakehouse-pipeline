import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Inicializa contexto
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Leitura de dados de entrada (exemplo: raw)
input_path = "s3://coingecko-staging-663354324751"
df = spark.read.json(input_path)

# Simples transformação: seleciona algumas colunas
df_clean = df.select("id", "symbol", "name", "current_price")

# Escrita no bucket Bronze
output_path = "s3://coingecko-silver-663354324751/bronze/"
df_clean.write.mode("overwrite").parquet(output_path)

job.commit()