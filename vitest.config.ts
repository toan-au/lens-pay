import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

// Deliberately a separate file from vite.config.ts: Vitest auto-prefers
// vitest.config.ts, so vite-plugin-ruby (which rewrites `base`, resolves virtual
// entrypoints and reads config/vite.json) never loads under test.
export default defineConfig({
  plugins: [vue()],
  test: {
    globals: true,
    environment: 'jsdom',
    environmentOptions: { jsdom: { url: 'http://localhost/' } },
    setupFiles: ['app/frontend/test/setup.ts'],
    include: ['app/frontend/**/*.spec.ts'],
    css: false,
    env: { TZ: 'UTC' }, // pins ICU output for utils/format.ts
    clearMocks: true,
    restoreMocks: true,
    unstubGlobals: true,
    coverage: {
      provider: 'v8',
      reportsDirectory: 'coverage',
      reporter: ['text', 'html', 'lcov'],
      include: ['app/frontend/**/*.{ts,vue}'],
      exclude: [
        'app/frontend/**/*.spec.ts',
        'app/frontend/test/**',
        'app/frontend/api/types.ts',
        'app/frontend/entrypoints/**',
      ],
    },
  },
})
