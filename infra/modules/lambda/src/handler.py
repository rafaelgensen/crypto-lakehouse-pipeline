import boto3
import os
import re

def create_glue_catalog():
    glue = boto3.client("glue")
    s3 = boto3.client("s3")

    silver_db = "silver"
    gold_db = "gold"

    # Buckets
    silver_bucket = os.environ.get("S3_BUCKET_SILVER", "coingecko-silver-663354324751")
    gold_bucket   = os.environ.get("S3_BUCKET_GOLD", "coingecko-gold-663354324751")

    silver_prefix = "silver/"
    gold_prefix   = "gold/"

    # 1. Cria databases se não existirem
    for db_name in [silver_db, gold_db]:
        try:
            glue.create_database(DatabaseInput={"Name": db_name})
        except glue.exceptions.AlreadyExistsException:
            pass

    # 2. Cria tabelas (com partições)
    table_defs = [
        {
            "db": silver_db,
            "name": "coins",
            "bucket": silver_bucket,
            "prefix": silver_prefix,
            "columns": [
                {"Name": "id", "Type": "string"},
                {"Name": "name", "Type": "string"},
                {"Name": "symbol", "Type": "string"},
                {"Name": "current_price", "Type": "decimal(18,4)"},
                {"Name": "last_updated", "Type": "timestamp"},
            ]
        },
        {
            "db": gold_db,
            "name": "coin_aggregates",
            "bucket": gold_bucket,
            "prefix": gold_prefix,
            "columns": [
                {"Name": "id", "Type": "string"},
                {"Name": "name", "Type": "string"},
                {"Name": "symbol", "Type": "string"},
                {"Name": "avg_price_usd", "Type": "decimal(18,4)"},
                {"Name": "min_price_usd", "Type": "decimal(18,4)"},
                {"Name": "max_price_usd", "Type": "decimal(18,4)"},
                {"Name": "records_count", "Type": "int"},
                {"Name": "last_updated", "Type": "timestamp"},
            ]
        }
    ]

    for t in table_defs:
        try:
            glue.create_table(
                DatabaseName=t["db"],
                TableInput={
                    "Name": t["name"],
                    "StorageDescriptor": {
                        "Columns": t["columns"],
                        "Location": f"s3://{t['bucket']}/{t['prefix']}",
                        "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
                        "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
                        "SerdeInfo": {
                            "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
                            "Parameters": {"serialization.format": "1"},
                        },
                    },
                    "PartitionKeys": [{"Name": "anomesdia", "Type": "string"}],
                    "TableType": "EXTERNAL_TABLE"
                }
            )
        except glue.exceptions.AlreadyExistsException:
            pass

    # 3. Registrar partições automaticamente
    def register_partitions(bucket, prefix, db, table):
        partitions = []
        paginator = s3.get_paginator("list_objects_v2")
        for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
            for obj in page.get("Contents", []):
                match = re.search(r"anomesdia=(\d{8})/", obj["Key"])
                if match:
                    anomesdia = match.group(1)
                    location = f"s3://{bucket}/{prefix}anomesdia={anomesdia}/"
                    part = {
                        "Values": [anomesdia],
                        "StorageDescriptor": {
                            "Columns": next(
                                t["columns"] for t in table_defs if t["db"] == db and t["name"] == table
                            ),
                            "Location": location,
                            "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
                            "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
                            "SerdeInfo": {
                                "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe",
                                "Parameters": {"serialization.format": "1"},
                            },
                        },
                    }
                    partitions.append(part)

        # Envia em lotes de até 100
        for i in range(0, len(partitions), 100):
            batch = partitions[i:i + 100]
            glue.batch_create_partition(DatabaseName=db, TableName=table, PartitionInputList=batch)

    register_partitions(silver_bucket, silver_prefix, silver_db, "coins")
    register_partitions(gold_bucket, gold_prefix, gold_db, "coin_aggregates")

def lambda_handler(event, context):
    create_glue_catalog()
    return {"statusCode": 200, "body": "Glue tables and partitions created successfully"}