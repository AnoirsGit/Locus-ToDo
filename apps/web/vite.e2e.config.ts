// TEMPORARY local e2e config (agent verification only) — not committed.
import { sveltekit } from '@sveltejs/kit/vite'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [tailwindcss(), sveltekit()],
  server: {
    host: '127.0.0.1',
    port: 53918,
    strictPort: true,
    proxy: { '/api': { target: 'http://127.0.0.1:53917', changeOrigin: true } },
  },
})
