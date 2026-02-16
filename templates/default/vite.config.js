import { defineConfig } from 'vite'

export default defineConfig({
  root: 'src',
  server: {
    allowedHosts: true
  },
  build: {
    outDir: '../dist',
    emptyOutDir: true
  }
})
