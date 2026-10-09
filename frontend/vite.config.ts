/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/graphql': {
        target: process.env.VITE_API_PROXY_TARGET ?? 'http://localhost:3000',
        // Keep the browser's Host header: the API compares the Origin header
        // with the request host (CSRF check, spec 06), so rewriting Host to
        // the api container would make every POST a 403.
        changeOrigin: false,
      },
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    css: true,
    exclude: ['**/node_modules/**', '**/playwright/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      thresholds: {
        lines: 80,
        statements: 80,
        branches: 80,
        functions: 80,
      },
      exclude: [
        'src/graphql/generated/**',
        'src/test/**',
        '**/*.d.ts',
        'playwright/**',
        'vite.config.ts',
      ],
    },
  },
})
