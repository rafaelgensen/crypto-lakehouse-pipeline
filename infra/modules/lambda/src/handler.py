import boto3
import os

def create_glue_catalog():
    glue = boto3.client("glue")

    silver_db = "silver"
    gold_db = "gold"

    # Buckets
    silver_bucket = os.environ.get("S3_BUCKET_SILVER", "coingecko-silver-663354324751")
    gold_bucket = os.environ.get("S3_BUCKET_GOLD", "coingecko-gold-663354324751")

    # 1. Cria os databases se não existirem
    for db_name in [silver_db, gold_db]:
        try:
            glue.create_database(DatabaseInput={"Name": db_name})
        except glue.exceptions.AlreadyExistsException:
            pass  # ignora se já existe

    # 2. Cria a tabela silver.coins
    try:
        glue.create_table(
            DatabaseName=silver_db,
            TableInput={
                "Name": "coins",
                "StorageDescriptor": {
                    "Columns": [
                        {"Name": "id", "Type": "string"},
                        {"Name": "name", "Type": "string"},
                        {"Name": "symbol", "Type": "string"},
                        {"Name": "current_price", "Type": "decimal(18,4)"},
                        {"Name": "last_updated", "Type": "timestamp"},
                        {"Name": "anomesdia", "Type": "string"},
                    ],
                    "Location": f"s3://{silver_bucket}/silver/coins/",
                    "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
                    "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
                    "SerdeInfo": {
                        "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
                        "Parameters": {"serialization.format": "1"},
                    }
                },
                "TableType": "EXTERNAL_TABLE"
            }
        )
    except glue.exceptions.AlreadyExistsException:
        pass

    # 3. Cria a tabela gold.coin_aggregates
    try:
        glue.create_table(
            DatabaseName=gold_db,
            TableInput={
                "Name": "coin_aggregates",
                "StorageDescriptor": {
                    "Columns": [
                        {"Name": "id", "Type": "string"},
                        {"Name": "name", "Type": "string"},
                        {"Name": "symbol", "Type": "string"},
                        {"Name": "anomesdia", "Type": "string"},
                        {"Name": "avg_price_usd", "Type": "decimal(18,4)"},
                        {"Name": "min_price_usd", "Type": "decimal(18,4)"},
                        {"Name": "max_price_usd", "Type": "decimal(18,4)"},
                        {"Name": "records_count", "Type": "int"},
                        {"Name": "last_updated", "Type": "timestamp"},
                    ],
                    "Location": f"s3://{gold_bucket}/gold/coin_aggregates/",
                    "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
                    "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
                    "SerdeInfo": {
                        "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
                        "Parameters": {"serialization.format": "1"},
                    }
                },
                "TableType": "EXTERNAL_TABLE"
            }
        )
    except glue.exceptions.AlreadyExistsException:
        pass

def lambda_handler(event, context):
    create_glue_catalog()
    return {
        "statusCode": 200,
        "body": "Glue databases and tables created successfully"
    }
