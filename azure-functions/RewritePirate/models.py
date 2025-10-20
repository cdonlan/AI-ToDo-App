import requests


def get_foundry_models(endpoint, api_key):
    # Use api-key header for Azure Cognitive Services endpoints
    if '.openai.azure.com' in endpoint or '.cognitiveservices.azure.com' in endpoint:
        headers = {
            'Content-Type': 'application/json',
            'api-key': api_key
        }
    else:
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {api_key}'
        }

    try:
        resp = requests.get(endpoint.rstrip('/') + '/models', headers=headers, timeout=30)
        resp.raise_for_status()
        result = resp.json()
        return result.get('models', [])
    except Exception:
        return []
