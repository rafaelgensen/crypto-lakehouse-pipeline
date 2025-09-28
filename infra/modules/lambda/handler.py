import boto3
import os

redshift = boto3.client('redshift-data')

def create_schemas():
    with open("/opt/create_schemas.sql", "r") as f:
        sql = f.read()

    response = redshift.execute_statement(
        WorkgroupName=os.environ['WORKGROUP_NAME'],
        Database=os.environ['DATABASE_NAME'],
        Sql=sql
    )
    return response

def lambda_handler(event, context):
    # Só chama create_schemas se evento indicar isso, senão retorna OK
    if event.get('action') == 'create_schemas':
        return create_schemas()
    else:
        return {"status": "waiting for activation"}