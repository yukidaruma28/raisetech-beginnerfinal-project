// @ts-check
import withNuxt from './.nuxt/eslint.config.mjs'

export default withNuxt(
  {
    ignores: [
      '.nuxt/**',
      '.output/**',
      'dist/**',
      'node_modules/**',
      // shadcn-vue が自動生成するコンポーネント（編集対象外）。
      'app/components/ui/**',
    ],
  },
  {
    rules: {
      // shadcn-vue のテンプレート関連でよく出る警告を緩和。
      'vue/multi-word-component-names': 'off',
    },
  },
)
