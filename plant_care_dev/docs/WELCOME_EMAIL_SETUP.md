# Приветственное письмо после регистрации (Trigger Email)

После регистрации пользователя Cloud Function `onUserCreate` записывает приветственное письмо в коллекцию Firestore `mail`. Чтобы письма реально отправлялись, нужно установить и настроить расширение **Trigger Email from Firestore**.

## 1. Установка расширения

1. Открой [Firebase Console](https://console.firebase.google.com/) → проект **plant-care-94574**.
2. В меню слева: **Extensions** (Расширения).
3. Нажми **Install extension** / «Установить расширение».
4. Найди расширение **Trigger Email from Firestore** (официальное от Firebase или с [extensions.dev](https://extensions.dev/extensions/firebase/firestore-send-email)) и нажми **Install**.

## 2. Настройка при установке

При установке расширения нужно указать:

| Параметр | Что указать |
|----------|-------------|
| **Cloud Functions location** | Тот же регион, что и у твоих функций (например `us-central1`). |
| **Collection path for emails** | `mail` — коллекция, в которую пишет наша функция. |
| **Email provider** | Выбери один: **SendGrid**, **Mailgun** или **SMTP** (Gmail, Mailjet и т.д.). |

Дальше ввод зависит от провайдера:

- **SendGrid**: зарегистрируйся на [sendgrid.com](https://sendgrid.com), создай API Key (Mail Send) и вставь его в настройки расширения.
- **Mailgun**: зарегистрируйся на [mailgun.com](https://www.mailgun.com), возьми API key и домен — введи в настройки.
- **SMTP** (например Gmail): укажи хост, порт (587 для TLS), email отправителя и пароль приложения (для Gmail — «Пароль приложения» из аккаунта Google).

Также задай **Email documents (from)** — адрес отправителя, например `noreply@твой-домен.com` или свой Gmail.

## 3. Правила Firestore для коллекции `mail`

Расширение создаёт документы в `mail` и обновляет их (статус доставки). Убедись, что в **Firestore → Rules** у коллекции `mail` есть правила, разрешающие запись от Cloud Functions (обычно расширение само настраивает доступ; если нет — добавь правило для `mail` так, чтобы писать могли только серверные операции).

## 4. Проверка

1. Задеплой функции (если ещё не задеплоены):
   ```bash
   cd plant_care && firebase deploy --only functions
   ```
2. Зарегистрируй нового тестового пользователя в приложении.
3. В Firestore в коллекции `mail` должен появиться новый документ с полями `to`, `message` (subject, text, html).
4. Расширение подхватит документ и отправит письмо. Статус можно смотреть в логах расширения или в самом документе (если расширение пишет туда delivery state).

## Формат документа (уже реализован в коде)

Функция `onUserCreate` создаёт документ в `mail` в формате:

```js
{
  to: "user@example.com",
  message: {
    subject: "Welcome to Plant Care! 🌱",
    text: "Hi Name! Thanks for signing up...",
    html: "<h2>Hi Name!</h2><p>Thanks for signing up...</p>"
  }
}
```

Он совместим с расширением Trigger Email — менять код не нужно.
