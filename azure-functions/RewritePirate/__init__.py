import logging
import azure.functions as func
import os
import json
import requests
from dotenv import load_dotenv

# This function rewrites a task as a pirate using Azure Foundry

load_dotenv()

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    
    # Add CORS headers to allow requests from the Vue app
    cors_headers = {
        'Access-Control-Allow-Origin': '*',  # In production, specify your domain
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
    }

    # Log method and headers for debugging and handle OPTIONS preflight early
    try:
        logging.info(f'Request method: {req.method}')
        logging.info(f'Request headers: {dict(req.headers)}')
    except Exception:
        logging.info('Could not read request headers for logging')

    # Handle OPTIONS request (CORS preflight) early before trying to parse a body
    if req.method and str(req.method).upper() == 'OPTIONS':
        # Return 204 No Content for preflight with CORS headers
        return func.HttpResponse('', status_code=204, headers=cors_headers)

    # Log the raw body for debugging and parse JSON
    try:
        raw_body = req.get_body().decode('utf-8')
        logging.info(f'Raw request body: {raw_body}')
        req_body = req.get_json()
    except ValueError as e:
        logging.error(f'JSON decode error: {str(e)}')
        return func.HttpResponse('Invalid JSON', status_code=400, headers=cors_headers)
        
    task = req_body.get('task')
    model = req_body.get('model')
    # Allow overriding the default deployment via environment variable, fallback to 'o4-mini'
    default_deployment = os.environ.get('AZURE_FOUNDRY_DEFAULT_DEPLOYMENT', 'o4-mini')
    if not model:
        model = default_deployment
    if not task or not model:
        return func.HttpResponse('Missing task or model', status_code=400, headers=cors_headers)

    # Example prompt for pirate-speak
    prompt = f"Rewrite this task as a pirate: {task}"

    # Use direct REST API call (no SDK required)
    endpoint = os.environ.get('AZURE_FOUNDRY_ENDPOINT')
    api_key = os.environ.get('AZURE_FOUNDRY_KEY')
    if not endpoint or not api_key:
        return func.HttpResponse('Azure Foundry credentials not set', status_code=500, headers=cors_headers)
        
    # For Azure OpenAI, the API format is:
    # https://{resource}.openai.azure.com/openai/deployments/{deployment-id}/chat/completions?api-version={api-version}
    # Log the raw endpoint for debugging
    logging.info("Raw endpoint: %s", endpoint)
    
    # If it's an Azure OpenAI/Cognitive Services endpoint, there are two supported forms:
    # 1) Full deployment URL (includes '/openai/deployments/{deployment}/...') -> use as-is
    # 2) Base resource URL (e.g. https://<resource>.cognitiveservices.azure.com) -> construct using the provided model as the deployment name
    if '.openai.azure.com' in endpoint or '.cognitiveservices.azure.com' in endpoint:
        if '/openai/deployments/' in endpoint:
            # User provided a full deployment endpoint (may already include api-version)
            endpoint = endpoint.rstrip()
            logging.info("Using provided full deployment endpoint: %s", endpoint)
        else:
            # Build the deployment URL using the model as the deployment name and a sensible default api-version
            base_url = endpoint.rstrip('/')
            api_version = '2025-01-01-preview'
            endpoint = f"{base_url}/openai/deployments/{model}/chat/completions?api-version={api_version}"
            logging.info("Constructed Azure OpenAI URL: %s", endpoint)

    # Headers used for the outbound API request to Azure Foundry / OpenAI
    # Use 'api-key' header for Azure OpenAI / Cognitive Services endpoints (the common approach for key auth)
    if '.openai.azure.com' in endpoint or '.cognitiveservices.azure.com' in endpoint:
        api_headers = {
            'Content-Type': 'application/json',
            'api-key': api_key
        }
    else:
        # Fallback to Authorization Bearer for other providers that may expect OAuth tokens
        api_headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {api_key}'
        }
    
    payload = {
        'model': model,
        'messages': [{'role': 'user', 'content': prompt}]
    }
    
    try:
        response = requests.post(endpoint, headers=api_headers, json=payload, timeout=30)
        response.raise_for_status()  # Raise exception for 4XX/5XX responses
        
        # Log raw response for debugging
        logging.info("Azure OpenAI raw response: %s", response.text[:2000] + ("..." if len(response.text) > 2000 else ""))
        
        try:
            result = response.json()
            # Log the full JSON structure to debug the response format
            logging.info("JSON response structure: %s", json.dumps(result))
            
            # Handle different response formats (OpenAI API vs Azure OpenAI)
            if 'choices' in result and len(result['choices']) > 0:
                # Handle nested structure with better error handling
                choice = result['choices'][0]
                if 'message' in choice and 'content' in choice['message']:
                    pirate_text = choice['message']['content']
                    return func.HttpResponse(pirate_text, status_code=200, headers={**cors_headers})
                elif 'text' in choice:  # Some APIs use 'text' directly
                    pirate_text = choice['text']
                    return func.HttpResponse(pirate_text, status_code=200, headers={**cors_headers})
            
            # If we get here, the response format wasn't recognized
            logging.error("Unexpected response structure: %s", json.dumps(result))
            return func.HttpResponse('Unexpected API response format. See logs for details.', status_code=502, headers=cors_headers)
        except (ValueError, KeyError, IndexError) as e:
            logging.error("Error parsing response JSON: %s", str(e))
            return func.HttpResponse('Invalid response format: ' + str(e), status_code=502, headers=cors_headers)
    except Exception as e:
        logging.error("Error calling Azure OpenAI: %s", str(e))
        return func.HttpResponse('Error calling Azure OpenAI: ' + str(e), status_code=500, headers=cors_headers)
