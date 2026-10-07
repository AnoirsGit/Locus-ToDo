import { dictionaries, type Locale } from './dictionaries';

let currentLocale = $state<Locale>('ru');

export const i18n = {
  get locale() { return currentLocale; },
  set locale(val: Locale) {
    currentLocale = val;
    if (typeof window !== 'undefined') {
      localStorage.setItem('lang', val);
      document.documentElement.lang = val;
    }
  },

  /** Re-apply the language saved in localStorage (browser only). */
  restore() {
    if (typeof localStorage === 'undefined') return;
    const saved = localStorage.getItem('lang');
    if (saved === 'ru' || saved === 'en') this.locale = saved;
  },

  t(path: string): string {
    const dict = dictionaries[currentLocale];
    const keys = path.split('.');
    let value: any = dict;

    for (const key of keys) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        return path;
      }
    }

    return typeof value === 'string' ? value : path;
  }
};
