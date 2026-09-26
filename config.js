/*
 * Подключение к базе Supabase.
 * Ключ publishable (anon) предназначен для браузера и может лежать в репозитории.
 * Ключ service_role / secret сюда класть НЕЛЬЗЯ.
 * Оставьте поля пустыми — приложение перейдёт в локальный режим (данные только в браузере).
 */
window.APP_CONFIG = {
  supabaseUrl: "https://awwhrlenhqoreagzfymn.supabase.co",
  supabaseKey: "sb_publishable_t94mAXN3a3ql6fGuoIf8Lg_HMrcSGiy"
};
