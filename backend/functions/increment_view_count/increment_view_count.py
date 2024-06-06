import json, boto3

client = boto3.client('dynamodb')

def lambda_handler(event, context):

    response = client.update_item(
        TableName='cloud_resume_view_count_table',
        Key = {
            'Statistics': {'S': 'view_count'}
        },
        UpdateExpression = 'ADD Visitors :inc',
        ExpressionAttributeValues = {":inc" : {"N": "1"}},
        ReturnValues = 'UPDATED_NEW'
        )

    value = response['Attributes']['Visitors']['N']

    return {
            'statusCode': 200,
            'body': value,
            'headers' : {
                'Access-Control-Allow-Origin': 'hirethisswellguy.com',
                'Access-Control-Allow-Methods': '*',
                'Access-Control-Allow-Headers': '*'
            }
    }
