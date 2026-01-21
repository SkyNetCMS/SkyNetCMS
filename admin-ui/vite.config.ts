import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  root: 'src',
  publicDir: '../public',
  base: '/sn_admin/',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        dashboard: resolve(__dirname, 'src/pages/dashboard/index.html'),
        registration: resolve(__dirname, 'src/pages/registration/index.html'),
      },
    },
  },
  server: {
    port: 3001,
  },
});
