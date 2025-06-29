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
    # Load credentials from the provided path
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
        
        # Test 1: getLocation query (should return null for non-existent location)
        print("\n🧪 Testing getLocation query...")
        get_location_query = """
        query GetLocation($accountId: String!, $locationId: String!) {
            getLocation(accountId: $accountId, locationId: $locationId) {
                ... on AddressLocation {
                    accountId
                    locationType
                    address {
                        streetAddress
                        city
                        postalCode
                        country
                    }
                }
                ... on CoordinatesLocation {
                    accountId
                    locationType
                    coordinates {
                        latitude
                        longitude
                        altitude
                        accuracy
                    }
                }
            }
        }
        """
        
        get_variables = {
            "accountId": "test-account-123",
            "locationId": "non-existent-location-id"
        }
        
        result = test_graphql_query(graphql_endpoint, token, get_location_query, get_variables)
        if result:
            print("✅ getLocation result:", json.dumps(result, indent=2))
        else:
            print("❌ getLocation failed")
        
        # Test 2: listLocations query
        print("\n🧪 Testing listLocations query...")
        list_locations_query = """
        query ListLocations($accountId: String!, $options: ListLocationsInput) {
            listLocations(accountId: $accountId, options: $options) {
                locations {
                    ... on AddressLocation {
                        accountId
                        locationType
                        address {
                            streetAddress
                            city
                            country
                        }
                    }
                    ... on CoordinatesLocation {
                        accountId
                        locationType
                        coordinates {
                            latitude
                            longitude
                        }
                    }
                }
                nextCursor
            }
        }
        """
        
        list_variables = {
            "accountId": "test-account-123",
            "options": {
                "limit": 10
            }
        }
        
        result = test_graphql_query(graphql_endpoint, token, list_locations_query, list_variables)
        if result:
            print("✅ listLocations result:", json.dumps(result, indent=2))
        else:
            print("❌ listLocations failed")
        
        # Test 3: createAddressLocation mutation
        print("\n🧪 Testing createAddressLocation mutation...")
        create_address_mutation = """
        mutation CreateAddressLocation($input: CreateAddressLocationInput!) {
            createAddressLocation(input: $input)
        }
        """
        
        address_variables = {
            "input": {
                "accountId": "test-account-123",
                "address": {
                    "streetAddress": "123 Main St",
                    "city": "San Francisco",
                    "stateProvince": "CA",
                    "postalCode": "94105",
                    "country": "US"
                }
            }
        }
        
        result = test_graphql_query(graphql_endpoint, token, create_address_mutation, address_variables)
        if result:
            print("✅ createAddressLocation result:", json.dumps(result, indent=2))
            
            # If creation was successful, test getting the created location
            location_id = result.get('data', {}).get('createAddressLocation')
            if location_id:
                print(f"\n🧪 Testing getLocation query for created address location {location_id}...")
                
                get_created_variables = {
                    "accountId": "test-account-123",
                    "locationId": location_id
                }
                
                get_result = test_graphql_query(graphql_endpoint, token, get_location_query, get_created_variables)
                if get_result:
                    print("✅ getLocation (created address) result:", json.dumps(get_result, indent=2))
                else:
                    print("❌ getLocation (created address) failed")
        else:
            print("❌ createAddressLocation failed")
        
        # Test 4: createCoordinatesLocation mutation
        print("\n🧪 Testing createCoordinatesLocation mutation...")
        create_coordinates_mutation = """
        mutation CreateCoordinatesLocation($input: CreateCoordinatesLocationInput!) {
            createCoordinatesLocation(input: $input)
        }
        """
        
        coordinates_variables = {
            "input": {
                "accountId": "test-account-123",
                "coordinates": {
                    "latitude": 37.7749,
                    "longitude": -122.4194,
                    "accuracy": 10.0
                }
            }
        }
        
        result = test_graphql_query(graphql_endpoint, token, create_coordinates_mutation, coordinates_variables)
        if result:
            print("✅ createCoordinatesLocation result:", json.dumps(result, indent=2))
            
            # If creation was successful, test getting the created location
            location_id = result.get('data', {}).get('createCoordinatesLocation')
            if location_id:
                print(f"\n🧪 Testing getLocation query for created coordinates location {location_id}...")
                
                get_created_variables = {
                    "accountId": "test-account-123",
                    "locationId": location_id
                }
                
                get_result = test_graphql_query(graphql_endpoint, token, get_location_query, get_created_variables)
                if get_result:
                    print("✅ getLocation (created coordinates) result:", json.dumps(get_result, indent=2))
                    
                    # Test 5: updateCoordinatesLocation mutation
                    print(f"\n🧪 Testing updateCoordinatesLocation mutation for {location_id}...")
                    update_coordinates_mutation = """
                    mutation UpdateCoordinatesLocation($locationId: String!, $input: UpdateCoordinatesLocationInput!) {
                        updateCoordinatesLocation(locationId: $locationId, input: $input)
                    }
                    """
                    
                    update_coordinates_variables = {
                        "locationId": location_id,
                        "input": {
                            "accountId": "test-account-123",
                            "coordinates": {
                                "latitude": 40.7128,
                                "longitude": -74.0060,
                                "accuracy": 5.0
                            }
                        }
                    }
                    
                    update_result = test_graphql_query(graphql_endpoint, token, update_coordinates_mutation, update_coordinates_variables)
                    if update_result:
                        print("✅ updateCoordinatesLocation result:", json.dumps(update_result, indent=2))
                        
                        # Test 6: deleteLocation mutation
                        print(f"\n🧪 Testing deleteLocation mutation for {location_id}...")
                        delete_location_mutation = """
                        mutation DeleteLocation($accountId: String!, $locationId: String!) {
                            deleteLocation(accountId: $accountId, locationId: $locationId)
                        }
                        """
                        
                        delete_variables = {
                            "accountId": "test-account-123",
                            "locationId": location_id
                        }
                        
                        delete_result = test_graphql_query(graphql_endpoint, token, delete_location_mutation, delete_variables)
                        if delete_result:
                            print("✅ deleteLocation result:", json.dumps(delete_result, indent=2))
                        else:
                            print("❌ deleteLocation failed")
                    else:
                        print("❌ updateCoordinatesLocation failed")
                else:
                    print("❌ getLocation (created coordinates) failed")
        else:
            print("❌ createCoordinatesLocation failed")
        
        # Test 7: updateAddressLocation mutation (if we created an address location earlier)
        address_location_id = None
        if result and result.get('data', {}).get('createAddressLocation'):
            address_location_id = result['data']['createAddressLocation']
        
        # Create another address location specifically for update testing
        print("\n🧪 Creating another address location for update testing...")
        test_address_result = test_graphql_query(graphql_endpoint, token, create_address_mutation, address_variables)
        if test_address_result:
            address_location_id = test_address_result.get('data', {}).get('createAddressLocation')
            
        if address_location_id:
            print(f"\n🧪 Testing updateAddressLocation mutation for {address_location_id}...")
            update_address_mutation = """
            mutation UpdateAddressLocation($locationId: String!, $input: UpdateAddressLocationInput!) {
                updateAddressLocation(locationId: $locationId, input: $input)
            }
            """
            
            update_address_variables = {
                "locationId": address_location_id,
                "input": {
                    "accountId": "test-account-123",
                    "address": {
                        "streetAddress": "456 Oak Ave",
                        "city": "New York",
                        "stateProvince": "NY",
                        "postalCode": "10001",
                        "country": "US"
                    }
                }
            }
            
            update_result = test_graphql_query(graphql_endpoint, token, update_address_mutation, update_address_variables)
            if update_result:
                print("✅ updateAddressLocation result:", json.dumps(update_result, indent=2))
            else:
                print("❌ updateAddressLocation failed")
        
        print("\n🎉 Complete Location API testing completed!")
        
    except Exception as e:
        print(f"Error during testing: {e}")

if __name__ == "__main__":
    main()