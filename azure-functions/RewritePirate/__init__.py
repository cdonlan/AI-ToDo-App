import logging
import azure.functions as func
import os
import requests

# This function rewrites a task as a pirate using Azure Foundry

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse('Invalid JSON', status_code=400)

    task = req_body.get('task')
    model = req_body.get('model')
    if not task or not model:
        return func.HttpResponse('Missing task or model', status_code=400)

    # Example prompt for pirate-speak
    prompt = f"Rewrite this task as a pirate: {task}"

    # Call Azure Foundry endpoint (replace with your endpoint and key)
    endpoint = os.environ.get('AZURE_FOUNDRY_ENDPOINT')
    api_key = os.environ.get('AZURE_FOUNDRY_KEY')
    if not endpoint or not api_key:
        return func.HttpResponse('Azure Foundry credentials not set', status_code=500)

    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {api_key}'
    }
    data = {
        'model': model,
        'messages': [
            { 'role': 'user', 'content': prompt }
        ]
    }
    try:
        resp = requests.post(endpoint, headers=headers, json=data, timeout=30)
        resp.raise_for_status()
        result = resp.json()
        pirate_text = result['choices'][0]['message']['content']
        return func.HttpResponse(pirate_text, status_code=200)
    except Exception as e:
        logging.error(str(e))
        return func.HttpResponse('Error calling Azure Foundry', status_code=500)
