#!/usr/bin/env python3

import json
import boto3
import requests

def test_crud_operations():
    # Get credentials and authenticate
    with open('user_creds.json', 'r') as f:
        creds = json.load(f)

    client = boto3.client('cognito-idp', region_name='us-east-1')
    response = client.initiate_auth(
        ClientId='26ff1cak7mpeqgcc4dsn3fbmel',
        AuthFlow='USER_PASSWORD_AUTH',
        AuthParameters={
            'USERNAME': creds['user'],
            'PASSWORD': creds['password']
        }
    )

    token = response['AuthenticationResult']['AccessToken']
    endpoint = 'https://bff.steverhoton.com/graphql'
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {token}'
    }

    print('🧪 Testing complete CRUD workflow...\n')

    # 1. List existing units
    print('1. Testing listUnits...')
    list_query = '''
    query ListUnits($input: ListUnitsInput!) {
      listUnits(input: $input) {
        items {
          id
          accountId
          make
          model
          modelYear
        }
        count
      }
    }
    '''

    list_result = requests.post(endpoint, json={
        'query': list_query,
        'variables': {'input': {'accountId': 'test-account-123', 'limit': 10}}
    }, headers=headers).json()

    print(f'   📋 Found {list_result["data"]["listUnits"]["count"]} existing units')

    # 2. Create a new unit
    print('\n2. Testing createUnit...')
    create_mutation = '''
    mutation CreateUnit($input: CreateUnitInput!) {
      createUnit(input: $input) {
        id
        accountId
        make
        model
        modelYear
        suggestedVin
        createdAt
      }
    }
    '''

    create_result = requests.post(endpoint, json={
        'query': create_mutation,
        'variables': {
            'input': {
                'accountId': 'test-account-123',
                'suggestedVin': '3HGBH41JXMN109188',
                'make': 'Toyota',
                'manufacturerName': 'Toyota Motor Co.',
                'model': 'Camry',
                'modelYear': '2022',
                'series': 'LE',
                'vehicleType': 'Passenger Car'
            }
        }
    }, headers=headers).json()

    if 'data' in create_result and create_result['data']['createUnit']:
        unit_id = create_result['data']['createUnit']['id']
        print(f'   ✅ Created unit {unit_id} (Toyota Camry 2022)')
        
        # 3. Get the specific unit
        print('\n3. Testing getUnit...')
        get_query = '''
        query GetUnit($id: ID!, $accountId: String!) {
          getUnit(id: $id, accountId: $accountId) {
            id
            accountId
            make
            model
            modelYear
            suggestedVin
            createdAt
            updatedAt
          }
        }
        '''
        
        get_result = requests.post(endpoint, json={
            'query': get_query,
            'variables': {
                'id': unit_id,
                'accountId': 'test-account-123'
            }
        }, headers=headers).json()
        
        if 'data' in get_result and get_result['data']['getUnit']:
            print(f'   ✅ Retrieved unit: {get_result["data"]["getUnit"]["make"]} {get_result["data"]["getUnit"]["model"]}')
        else:
            print('   ❌ getUnit failed')
            print(f'   Response: {json.dumps(get_result, indent=2)}')
        
        # 4. Update the unit
        print('\n4. Testing updateUnit...')
        update_mutation = '''
        mutation UpdateUnit($input: UpdateUnitInput!) {
          updateUnit(input: $input) {
            id
            make
            model
            modelYear
            updatedAt
          }
        }
        '''
        
        update_result = requests.post(endpoint, json={
            'query': update_mutation,
            'variables': {
                'input': {
                    'id': unit_id,
                    'accountId': 'test-account-123',
                    'modelYear': '2023'
                }
            }
        }, headers=headers).json()
        
        if 'data' in update_result and update_result['data'] and update_result['data']['updateUnit']:
            print(f'   ✅ Updated unit to model year {update_result["data"]["updateUnit"]["modelYear"]}')
        else:
            print('   ❌ updateUnit failed')
            print(f'   Response: {json.dumps(update_result, indent=2)}')
        
        # 5. Delete the unit
        print('\n5. Testing deleteUnit...')
        delete_mutation = '''
        mutation DeleteUnit($id: ID!, $accountId: String!) {
          deleteUnit(id: $id, accountId: $accountId)
        }
        '''
        
        delete_result = requests.post(endpoint, json={
            'query': delete_mutation,
            'variables': {
                'id': unit_id,
                'accountId': 'test-account-123'
            }
        }, headers=headers).json()
        
        if 'data' in delete_result and delete_result['data'] and delete_result['data']['deleteUnit']:
            print('   ✅ Successfully deleted unit')
        else:
            print('   ❌ deleteUnit failed')
            print(f'   Response: {json.dumps(delete_result, indent=2)}')
    
    else:
        print('   ❌ createUnit failed')
        print(f'   Response: {json.dumps(create_result, indent=2)}')

    print('\n🎉 CRUD workflow test completed!')

if __name__ == "__main__":
    test_crud_operations()