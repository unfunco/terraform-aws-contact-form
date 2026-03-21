import json


def lambda_handler(event, _context):
    return {
        "statusCode": 501,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"message": "Not Implemented"}),
    }
