#!/usr/bin/env python3

import json
import boto3
import requests

# Configuration
user_pool_id = "us-east-1_plhb9FhBb"
client_id = "26ff1cak7mpeqgcc4dsn3fbmel"  # From previous test
graphql_endpoint = "https://bff.steverhoton.com/graphql"

# Load credentials
with open('user_creds.json', 'r') as f:
    creds = json.load(f)

# Get token
client = boto3.client('cognito-idp', region_name='us-east-1')
response = client.initiate_auth(
    ClientId=client_id,
    AuthFlow='USER_PASSWORD_AUTH',
    AuthParameters={
        'USERNAME': creds['user'],
        'PASSWORD': creds['password']
    }
)

token = response['AuthenticationResult']['AccessToken']
print("✅ Got authentication token")

# Test simple listUnits with debugging
headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {token}'
}

query = """
query ListUnits($input: ListUnitsInput!) {
    listUnits(input: $input) {
        count
        items {
            id
            accountId
        }
        nextToken
    }
}
"""

variables = {
    "input": {
        "accountId": "test-account-123",
        "limit": 5
    }
}

payload = {
    'query': query,
    'variables': variables
}

print("🧪 Testing listUnits with detailed response...")
response = requests.post(graphql_endpoint, json=payload, headers=headers)

print(f"Status Code: {response.status_code}")
print(f"Response Headers: {dict(response.headers)}")
print(f"Response Body: {response.text}")

# Also test the direct AppSync endpoint
direct_endpoint = "https://aqsww2lpmveftbi6hseu5nsl6q.appsync-api.us-east-1.amazonaws.com/graphql"
print(f"\n🧪 Testing direct AppSync endpoint...")
response2 = requests.post(direct_endpoint, json=payload, headers=headers)

print(f"Direct Status Code: {response2.status_code}")
print(f"Direct Response: {response2.text}")