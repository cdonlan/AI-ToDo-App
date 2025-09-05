import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: '/AIToDOApp/', // Use your repo name
  server: {
    // Configure CORS for development
    proxy: {
      // Proxy API requests to Azure Functions during development
      '/api': {
        target: 'http://localhost:7071',
        changeOrigin: true,
        rewrite: (path) => path
      }
    }
  }
})
