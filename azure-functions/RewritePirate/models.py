import requests

def get_foundry_models(endpoint, api_key):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {api_key}'
    }
    try:
        resp = requests.get(endpoint + '/models', headers=headers, timeout=30)
        resp.raise_for_status()
        result = resp.json()
        return result.get('models', [])
    except Exception as e:
        return []
