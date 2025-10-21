import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  use: {
    baseURL: 'http://localhost:5173/AI-ToDo-App/',
    trace: 'on-first-retry',
  },
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5173/AI-ToDo-App/',
    reuseExistingServer: true,
    timeout: 120000,
  },
});