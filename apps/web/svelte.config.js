import adapter from '@sveltejs/adapter-auto'
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte'

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter(),
    files: {
      appTemplate: 'src/app/app.html',
      routes: 'src/pages',
    },
    alias: {
      '$widgets/*': 'src/widgets/*',
      '$features/*': 'src/features/*',
      '$entities/*': 'src/entities/*',
      '$shared/*': 'src/shared/*',
      $widgets: 'src/widgets',
      $features: 'src/features',
      $entities: 'src/entities',
      $shared: 'src/shared',
    },
  },
}

export default config
