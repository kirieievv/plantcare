# План реализации: Plant Assistant после Health Check

Цель: выводить в блоке Plant Care Assistant структурированный ответ по сценариям «растение в порядке» и «есть проблема», без дублирования с блоком Care Recommendations.

---

## 1. Источники данных и разграничение

| Блок | Данные | Не показывать |
|------|--------|----------------|
| **Plant Care Assistant** | Только результат последней проверки: статус, похвала/диагностика, краткое состояние, действия (при проблеме), когда повторить проверку, поддержка. | care_recommendations, полив/свет/удобрения как справочник, сырой JSON. |
| **Care Recommendations** | Только общий уход: aiCareTips (полив, свет, почва и т.д.), Interesting Facts. | Статус проверки, health_assessment, «сейчас»-формулировки. |

Дублирования не будет: общий уход только в Care Recommendations, вывод проверки — только в Plant Care Assistant.

---

## 2. Backend (Cloud Function `analyzePlantPhoto`)

### 2.1 Расширить схему ответа ИИ

В промпте уже есть `health_assessment`. Добавить в JSON-схему блок **`plant_assistant`** (или отдельные поля на верхнем уровне), чтобы ИИ возвращал структуру для двух сценариев.

**Вариант A — один объект `plant_assistant`:**

```json
"plant_assistant": {
  "status": "healthy | issue_detected",
  "praise_phrase": "Отличная работа 👏",
  "health_summary": "Краткое описание состояния: листья, почва, тонус, отсутствие болезней (2–3 факта).",
  "maintenance_footer": "Ухаживайте дальше за растением согласно рекомендациям и отмечайте, когда полили 🌱",
  "problem_name": "Название проблемы (если issue)",
  "problem_description": "Краткое описание (если issue)",
  "severity": "mild | moderate | serious",
  "action_steps": ["Шаг 1", "Шаг 2", "..."],
  "follow_up_days": 5,
  "reassurance": "Не переживайте — растение можно восстановить 🌿"
}
```

- Для **healthy**: заполняются `praise_phrase`, `health_summary`, `maintenance_footer`; остальные поля пустые или не используются.
- Для **issue_detected**: заполняются `problem_name`, `problem_description`, `severity`, `action_steps`, `follow_up_days`, `reassurance`; при необходимости можно оставить и краткий `health_summary`.

**Вариант B** — не менять схему ИИ, а на бэкенде парсить текст `health_assessment` и собирать объект (сложнее и хрупче). Рекомендуется вариант A.

### 2.2 Проброс в ответе API

- В `transformNewJsonToLegacy` (или рядом) не затирать `health_assessment` и новый блок `plant_assistant`.
- В ответе клиенту в `recommendations` добавить и отдавать:
  - `plant_assistant` (объект как выше) и/или
  - `health_assessment` (строка) — на случай упрощённого клиента или fallback.
- Продолжать отдавать `care_tips` (для Care Recommendations) и не включать их в текст блоков Plant Assistant.

### 2.3 Файлы

- [plant_care/functions/index.js](plant_care/functions/index.js): промпт (схема JSON), парсинг ответа, добавление `plant_assistant` и `health_assessment` в объект, который уходит в `res.json({ recommendations })`.

---

## 3. Flutter: приём и сохранение результата проверки

### 3.1 Health Check Modal

- В [plant_care/lib/widgets/health_check_modal.dart](plant_care/lib/widgets/health_check_modal.dart) в `_callChatGPT` после получения `result`:
  - Читать `recommendations.plant_assistant` (и при отсутствии — fallback на `recommendations.health_assessment` / `general_description`).
  - Формировать объект для колбэка **не** из `rawResponse`, а из структуры для Plant Assistant:
    - `status`: `recommendations.plant_assistant?.status ?? (по эвристике из rawResponse, как сейчас)`.
    - `plant_assistant`: весь объект `plant_assistant` или собранный вручную из `health_assessment` при отсутствии блока.
  - В колбэк передавать этот объект (например `healthResult['plant_assistant']`, `healthResult['status']`), а в качестве «сообщения» для сохранения в растение — либо JSON строку этого объекта, либо отдельные поля (см. ниже).

### 3.2 Сохранение в растение и модель Plant

- Сейчас: `healthStatus`, `healthMessage` (сейчас сюда пишется сырой JSON), `lastHealthCheck`.
- Варианты:
  - **Минимальный:** оставить `healthStatus` и `healthMessage`. В `healthMessage` сохранять **не** rawResponse, а JSON-строку объекта Plant Assistant (praise, summary, footer, problem_*, action_steps, follow_up_days, reassurance). В UI парсить и рендерить блоки.
  - **Расширенный:** добавить в модель Plant поля, например: `healthPraise`, `healthSummary`, `healthFooter`, `healthProblemName`, `healthProblemDescription`, `healthSeverity`, `healthActionSteps` (List<String> или одна строка с разделителем), `healthFollowUpDays`, `healthReassurance`. Тогда в Firestore и в `_handleHealthCheckComplete` обновлять эти поля из `plant_assistant`. Старые записи без полей — считать «нет данных» или fallback на парсинг `healthMessage`.

Рекомендация: начать с сохранения в `healthMessage` JSON-строки структуры Plant Assistant (минимальные изменения модели), затем при желании вынести в отдельные поля.

### 3.3 Обработчик на экране деталей

- В [plant_care/lib/screens/plant_details_screen.dart](plant_care/lib/screens/plant_details_screen.dart) в `_handleHealthCheckComplete`:
  - Писать в растение `healthStatus` из ответа.
  - Писать в растение «сообщение» из структуры Plant Assistant (JSON строка или отдельные поля).
  - Обновлять `aiCareTips` и остальное для Care Recommendations как сейчас (без изменений логики), чтобы дублирования не было.

---

## 4. Flutter: отображение в Plant Care Assistant

### 4.1 Разбор данных

- В `_buildAiCareCard`:
  - Если есть новые поля (например `healthPraise`, `healthSummary`) — использовать их.
  - Иначе парсить `healthMessage`: если это JSON с полями `praise_phrase`, `health_summary` и т.д. — использовать их; если нет (старая запись с сырым ответом) — fallback: показывать нейтральное сообщение или попытаться вытащить один абзац из текста, **не** выводить сырой JSON.

### 4.2 Сценарий: растение в порядке (`status == 'ok'` / `healthy`)

Рендерить три блока по макету:

1. **Похвала (Positive Reinforcement)**  
   Текст из `plant_assistant.praise_phrase` или запасная фраза («Отличная работа 👏» / «Так держать!»).

2. **Текущее состояние (Health Summary)**  
   Текст из `plant_assistant.health_summary` (общее заключение + 2–3 факта). Один блок с подзаголовком при желании.

3. **Подпись (Maintenance Footer)**  
   Текст из `plant_assistant.maintenance_footer` или фиксированный: «Ухаживайте дальше за растением согласно рекомендациям и отмечайте, когда полили 🌱».

Не показывать: длинный текст, JSON, рекомендации по поливу/свету (они в Care Recommendations).

### 4.3 Сценарий: есть проблема (`status == 'issue'` / `issue_detected`)

Рендерить четыре блока:

1. **Диагностика (Problem Identification)**  
   - Заголовок / название: `problem_name`.  
   - Текст: `problem_description`.  
   - Степень: `severity` (лёгкая / средняя / серьёзная) — отобразить текстом или бейджем.

2. **План действий (Action Plan)**  
   Список из `action_steps` (максимум 3–5 пунктов). Без общих советов из care_tips.

3. **Когда повторить проверку (Follow-up)**  
   Один абзац: «Проверьте растение снова через X дней.» Значение из `follow_up_days` (при отсутствии — по умолчанию из severity: лёгкая 5–7, средняя 3–5, серьёзная 2–3).

4. **Поддержка (Reassurance)**  
   Текст из `reassurance`. Если пусто — не показывать блок или показать нейтральную фразу.

Не показывать: сырой JSON, care_recommendations, полный health_assessment как один кусок текста (только разложенное по блокам).

### 4.4 Убрать из текущей карточки

- Не выводить `_plant.healthMessage` «как есть» (сейчас там сырой ответ).
- Не выводить `_removeInterestingFactsFromMessage` / `_removeFactsAndAssessmentFromMessage` для сырого текста — только структурированные блоки из `plant_assistant`.
- Quick Help Tips при проблеме заменить на список из `action_steps` из ответа; если пусто — оставить короткий запасной список или скрыть.

---

## 5. Обратная совместимость

- Старые растения: `healthMessage` может быть сырым JSON или старым форматом.
  - При рендере: если парсинг `healthMessage` как JSON не даёт объект с `praise_phrase` / `health_summary` / `action_steps` и т.д., считать данные «старыми».
  - Fallback: показывать короткое сообщение вроде «Результат проверки сохранён» и ссылку на Care Recommendations, либо одну строку из `health_assessment`, если её удаётся извлечь из текста (без вывода всего JSON).
- Новые проверки: всегда сохранять структуру Plant Assistant (в `healthMessage` как JSON или в новых полях).

---

## 6. Порядок внедрения

1. **Backend:** добавить в промпт и схему ИИ блок `plant_assistant`, парсить его в ответе и отдавать в `recommendations` (и при необходимости отдельно `health_assessment`).
2. **Flutter — данные:** в health_check_modal брать `plant_assistant` и `status`, передавать в колбэк; в `_handleHealthCheckComplete` сохранять в растение (healthMessage как JSON структуры или новые поля).
3. **Flutter — UI:** переписать `_buildAiCareCard`: два сценария (healthy / issue), блоки по спецификации, без сырого сообщения и без дублирования с Care Recommendations.
4. **Fallback и тесты:** обработать старые записи и проверить оба сценария (здоровое растение и с проблемой).

---

## 7. Файлы для правок

| Компонент | Файл |
|-----------|------|
| Промпт и ответ API | [plant_care/functions/index.js](plant_care/functions/index.js) |
| Приём ответа проверки | [plant_care/lib/widgets/health_check_modal.dart](plant_care/lib/widgets/health_check_modal.dart) |
| Сохранение в растение | [plant_care/lib/screens/plant_details_screen.dart](plant_care/lib/screens/plant_details_screen.dart) (`_handleHealthCheckComplete`) |
| Рендер карточки | [plant_care/lib/screens/plant_details_screen.dart](plant_care/lib/screens/plant_details_screen.dart) (`_buildAiCareCard`) |
| Модель (опционально) | [plant_care/lib/models/plant.dart](plant_care/lib/models/plant.dart) |

После выполнения плана блок Plant Care Assistant будет показывать только результат проверки по заданной логике, а Care Recommendations останется единственным местом для общей информации по уходу, без дублирования.
