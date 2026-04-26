import tailwindcss from '@tailwindcss/vite'

// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  modules: ['shadcn-nuxt', '@nuxt/eslint'],

  eslint: {
    config: {
      stylistic: false,
    },
  },

  css: ['~/assets/css/tailwind.css'],

  vite: {
    plugins: [tailwindcss()],
  },

  shadcn: {
    prefix: '',
    componentDir: './app/components/ui',
  },

  runtimeConfig: {
    // server-side only: backend コンテナへの直接 URL（本番: http://backend:80）
    apiBaseUrl: process.env.API_BASE_URL || '',
    public: {
      // client-side: 本番は空文字（nginx 経由の同一オリジン相対パス）
      apiBaseUrl: process.env.NUXT_PUBLIC_API_BASE_URL || 'http://localhost:3001',
    },
  },

  app: {
    head: {
      title: 'Inquiry Board',
      htmlAttrs: { lang: 'ja' },
    },
  },

  devServer: {
    port: 3000,
  },
})
