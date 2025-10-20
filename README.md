# Vue 3 + Vite

This template should help get you started developing with Vue 3 in Vite. The template uses Vue 3 `<script setup>` SFCs, check out the [script setup docs](https://v3.vuejs.org/api/sfc-script-setup.html#sfc-script-setup) to learn more.

## Testing

This project uses [Playwright](https://playwright.dev/) for end-to-end testing.

### Prerequisites

1. Install dependencies:
   ```bash
   npm install
   ```

2. Install Playwright browsers (first time only):
   ```bash
   npx playwright install
   ```

### Running Tests

Run all tests:
```bash
npm test
```

Run tests in headed mode (see the browser):
```bash
npm run test:headed
```

Run tests in UI mode (interactive):
```bash
npm run test:ui
```

Run tests in debug mode:
```bash
npm run test:debug
```

### VSCode Integration

For the best testing experience in VSCode:

1. Install the recommended Playwright extension when prompted
2. Tests will appear in the Test Explorer sidebar
3. You can run individual tests, debug tests, and view results directly in VSCode

The Playwright Test extension provides:
- Test discovery in the Test Explorer
- Run and debug tests from the editor
- View test results and traces
- Record new tests


