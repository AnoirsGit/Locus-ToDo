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
