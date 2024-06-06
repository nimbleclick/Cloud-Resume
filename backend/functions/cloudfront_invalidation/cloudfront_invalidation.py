from time import time
import json, boto3

client = boto3.client('cloudfront')
distribution_id = 'REDACTED'

def lambda_handler(event, context):
    response = client.create_invalidation(
        DistributionId = distribution_id,
        InvalidationBatch = {
            'Paths': {
                'Quantity' : 1,
                'Items' : [
                    '/*'
                ]
            },
            'CallerReference' : str(time()).replace(".", "")
        }
    )

    status = response['Invalidation']['Status']
    id = response['Invalidation']['Id']

    return{
        'Status': status,
        'Invalidation ID' : id 
    }