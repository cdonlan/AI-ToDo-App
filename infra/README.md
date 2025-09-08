Infra folder — Bicep starter

Files:
- `main.bicep` — provision Storage account, App Service plan (consumption) and a Linux Function App (Python 3.11).
- `parameters.dev.json` — example parameter file for a development deployment.
- `parameters.prod.json` — example parameter file for production deployment.

Deploy example (requires az CLI + bicep):

az deployment group create --resource-group <rg> --template-file infra/main.bicep --parameters @infra/parameters.dev.json

Notes & next steps:
- You should not output secrets (storage keys) from Bicep — use Key Vault for secrets.
- Update `main.bicep` to add Key Vault and managed identity if you plan to store `AZURE_FOUNDRY_KEY` securely.
- Consider using GitHub Actions to run the Bicep deployment and then deploy the function app code.
