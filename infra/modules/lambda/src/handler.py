import boto3
import os
import re
import time

def create_glue_catalog():
    glue = boto3.client("glue")
    s3 = boto3.client("s3")

    silver_db = "silver"
    gold_db = "gold"

    silver_bucket = os.environ.get("S3_BUCKET_SILVER", "coingecko-silver-663354324751")
    gold_bucket   = os.environ.get("S3_BUCKET_GOLD", "coingecko-gold-663354324751")

    silver_prefix = "silver/"
    gold_prefix   = "gold/"

    # 1. Databases
    for db_name in [silver_db, gold_db]:
        try:
            glue.create_database(DatabaseInput={"Name": db_name})
        except glue.exceptions.AlreadyExistsException:
            pass

    # 2. Table definitions
    table_defs = {
        "silver": {
            "coins": {
                "bucket": silver_bucket,
                "prefix": silver_prefix,
                "columns": [
                    {"Name": "id", "Type": "string"},
                    {"Name": "name", "Type": "string"},
                    {"Name": "symbol", "Type": "string"},
                    {"Name": "current_price", "Type": "decimal(18,4)"},
                    {"Name": "last_updated", "Type": "timestamp"},
                ],
            }
        },
        "gold": {
            "coin_aggregates": {
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
                ],
            }
        },
    }

    # 3. Cria ou atualiza tabelas com PartitionKeys
    for db_name, tables in table_defs.items():
        for table_name, t in tables.items():
            table_input = {
                "Name": table_name,
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
                "TableType": "EXTERNAL_TABLE",
            }

            try:
                glue.create_table(DatabaseName=db_name, TableInput=table_input)
            except glue.exceptions.AlreadyExistsException:
                glue.update_table(DatabaseName=db_name, TableInput=table_input)

    # Espera propagação do catálogo
    time.sleep(3)

    # 4. Registrar partições automaticamente
    def register_partitions(bucket, prefix, db, table, columns):
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
                            "Columns": columns,
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

        # Batch create (100 máx)
        for i in range(0, len(partitions), 100):
            batch = partitions[i : i + 100]
            try:
                glue.batch_create_partition(DatabaseName=db, TableName=table, PartitionInputList=batch)
            except glue.exceptions.AlreadyExistsException:
                pass
            except glue.exceptions.InvalidInputException:
                # Ignora se partição já existir
                pass

    # silver
    register_partitions(
        silver_bucket,
        silver_prefix,
        "silver",
        "coins",
        table_defs["silver"]["coins"]["columns"],
    )
    # gold
    register_partitions(
        gold_bucket,
        gold_prefix,
        "gold",
        "coin_aggregates",
        table_defs["gold"]["coin_aggregates"]["columns"],
    )

def lambda_handler(event, context):
    create_glue_catalog()
    return {"statusCode": 200, "body": "Glue tables and partitions created successfully"}