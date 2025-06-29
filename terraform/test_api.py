#!/usr/bin/env python3

import json
import boto3
import requests
from botocore.exceptions import ClientError

def get_cognito_token(username, password, user_pool_id, client_id):
    """Authenticate with Cognito and get JWT token"""
    client = boto3.client('cognito-idp', region_name='us-east-1')
    
    try:
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )
        
        return response['AuthenticationResult']['AccessToken']
    except ClientError as e:
        print(f"Authentication failed: {e}")
        return None

def test_graphql_query(endpoint, token, query, variables=None):
    """Test a GraphQL query with authentication"""
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {token}'
    }
    
    payload = {
        'query': query
    }
    
    if variables:
        payload['variables'] = variables
    
    try:
        response = requests.post(endpoint, json=payload, headers=headers)
        return response.json()
    except Exception as e:
        print(f"Request failed: {e}")
        return None

def main():
    # Load credentials
    with open('/Users/steverhoton/git/tmp/pass.json', 'r') as f:
        creds = json.load(f)
    
    # Configuration (from terraform outputs)
    user_pool_id = "us-east-1_plhb9FhBb"
    graphql_endpoint = "https://bff.steverhoton.com/graphql"
    
    # First, get the client ID from the user pool
    cognito_client = boto3.client('cognito-idp', region_name='us-east-1')
    
    try:
        # List user pool clients to find one that supports USER_PASSWORD_AUTH
        clients_response = cognito_client.list_user_pool_clients(
            UserPoolId=user_pool_id,
            MaxResults=60
        )
        
        client_id = None
        for client in clients_response['UserPoolClients']:
            # Get client details to check auth flows
            client_details = cognito_client.describe_user_pool_client(
                UserPoolId=user_pool_id,
                ClientId=client['ClientId']
            )
            
            explicit_flows = client_details['UserPoolClient'].get('ExplicitAuthFlows', [])
            if 'ALLOW_USER_PASSWORD_AUTH' in explicit_flows:
                client_id = client['ClientId']
                print(f"Found compatible client: {client_id}")
                break
        
        if not client_id:
            print("No compatible Cognito client found that supports USER_PASSWORD_AUTH")
            return
        
        # Authenticate and get token
        print("Authenticating with Cognito...")
        token = get_cognito_token(creds['user'], creds['password'], user_pool_id, client_id)
        
        if not token:
            print("Failed to get authentication token")
            return
        
        print("✅ Authentication successful!")
        
        # Test 1: validateAuthn query
        print("\n🧪 Testing validateAuthn query...")
        validate_query = """
        query {
            validateAuthn {
                message
                timestamp
                user
                success
            }
        }
        """
        
        result = test_graphql_query(graphql_endpoint, token, validate_query)
        if result:
            print("✅ validateAuthn result:", json.dumps(result, indent=2))
        else:
            print("❌ validateAuthn failed")
        
        # Test 2: List units query
        print("\n🧪 Testing listUnits query...")
        list_query = """
        query ListUnits($input: ListUnitsInput!) {
            listUnits(input: $input) {
                items {
                    id
                    accountId
                    suggestedVin
                    make
                    model
                    modelYear
                }
                count
                nextToken
            }
        }
        """
        
        list_variables = {
            "input": {
                "accountId": "test-account-123",
                "limit": 10
            }
        }
        
        result = test_graphql_query(graphql_endpoint, token, list_query, list_variables)
        if result:
            print("✅ listUnits result:", json.dumps(result, indent=2))
        else:
            print("❌ listUnits failed")
        
        # Test 3: Create unit mutation
        print("\n🧪 Testing createUnit mutation...")
        create_mutation = """
        mutation CreateUnit($input: CreateUnitInput!) {
            createUnit(input: $input) {
                id
                accountId
                suggestedVin
                make
                model
                modelYear
                createdAt
            }
        }
        """
        
        create_variables = {
            "input": {
                "accountId": "test-account-123",
                "suggestedVin": "1HGBH41JXMN109186",
                "make": "Honda",
                "manufacturerName": "Honda Motor Co.",
                "model": "Civic",
                "modelYear": "2021",
                "series": "Sport",
                "vehicleType": "Passenger Car"
            }
        }
        
        result = test_graphql_query(graphql_endpoint, token, create_mutation, create_variables)
        if result:
            print("✅ createUnit result:", json.dumps(result, indent=2))
            
            # If creation was successful, test getting the created unit
            if result.get('data', {}).get('createUnit', {}).get('id'):
                unit_id = result['data']['createUnit']['id']
                account_id = result['data']['createUnit']['accountId']
                
                print(f"\n🧪 Testing getUnit query for created unit {unit_id}...")
                get_query = """
                query GetUnit($id: ID!, $accountId: String!) {
                    getUnit(id: $id, accountId: $accountId) {
                        id
                        accountId
                        suggestedVin
                        make
                        model
                        modelYear
                        createdAt
                        updatedAt
                    }
                }
                """
                
                get_variables = {
                    "id": unit_id,
                    "accountId": account_id
                }
                
                get_result = test_graphql_query(graphql_endpoint, token, get_query, get_variables)
                if get_result:
                    print("✅ getUnit result:", json.dumps(get_result, indent=2))
                else:
                    print("❌ getUnit failed")
        else:
            print("❌ createUnit failed")
        
        print("\n🎉 API testing completed!")
        
    except Exception as e:
        print(f"Error during testing: {e}")

if __name__ == "__main__":
    main()