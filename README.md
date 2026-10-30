# Commitly

**Git-based task manager** — управление задачами через Git-репозитории. Никаких баз данных и облачных сервисов: все данные хранятся в файлах репозитория.

## 🚀 Возможности

- **Git-репозитории как проекты** — каждый репозиторий становится проектом
- **Задачи как папки** — структура `tasks/001/`, `tasks/002/` и т.д.
- **Markdown-описания** — полноценная поддержка Markdown в описаниях задач
- **Комментарии** — обсуждение задач с YAML-frontmatter (автор, дата)
- **Вложения** — прикрепление файлов к задачам
- **Теги и исполнители** — организация задач через теги и назначение ответственных
- **Мульти-сервер** — GitHub, GitLab, Gitea, произвольный Git-сервер
- **Локализация** — английский и русский язык (автоопределение из системы)
- **Офлайн-режим** — кэширование данных в локальное хранилище
- **Синхронизация** — pull/push изменений через Git

## 📁 Структура репозитория

```
repository/
├── metadata.json              # Метаданные проекта (название и др.)
└── tasks/
    └── 001/
        ├── metadata.json      # Метаданные задачи (assignee, tags, dates)
        ├── description.md     # Описание задачи (Markdown)
        ├── attachments/       # Вложения
        │   └── file.pdf
        └── comments/
            ├── 001.md         # Комментарий #1
            └── 002.md         # Комментарий #2
```

### Формат файлов

**`metadata.json`** (проект):
```json
{
  "name": "Мой Проект"
}
```

**`metadata.json`** (задача):
```json
{
  "id": 1,
  "assignee": "username",
  "tags": ["feature", "backend"],
  "created": "2025-01-15T10:30:00Z",
  "updated": "2025-01-15T14:20:00Z"
}
```

**`NNNN.md`** (комментарий):
```markdown
---
author: username
date: 2025-01-15T14:20:00Z
---

Текст комментария с поддержкой Markdown
```

## 🛠 Технологии

| Слой | Технология |
|------|-----------|
| Фреймворк | Flutter 3.x (Dart) |
| Управление состоянием | Riverpod |
| Навигация | go_router |
| HTTP-клиент | Dio |
| Хранение | shared_preferences, secure storage |
| Markdown | flutter_markdown |
| Локализация | flutter_localizations |

## 📦 Установка

### Требования

- Flutter SDK ≥ 3.12.2
- Dart ≥ 3.12
- iOS 12+ / Android 5.0+ / macOS

### Шаги

```bash
# Клонируйте репозиторий
git clone https://github.com/your-org/commitly.git
cd commitly

# Установите зависимости
flutter pub get

# Запустите приложение
flutter run
```

## 🔧 Сборка

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release
```

## ⚙️ Настройка Git-сервера

### GitHub

1. Создайте Personal Access Token: Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Разрешения: `repo` (для private репозиториев)
3. В приложении: Base URL `https://api.github.com`

### GitLab

1. Создайте Personal Access Token: Preferences → Access Tokens
2. Разрешения: `read_api`
3. В приложении: Base URL `https://gitlab.com` или ваш self-hosted

### Gitea / Gitverse

1. Создайте токен: Settings → Applications → Generate token
2. В приложении: Base URL `https://your-instance.com`

### Произвольный сервер

Укажите любой URL, поддерживающий REST API для Git (GitHub-compatible API).

## 🏗 Архитектура

```
lib/
├── app.dart                    # Корневой вид, настройка роутера
├── main.dart                   # Точка входа
├── core/                       # Утилиты, исключения
├── data/
│   ├── models/                 # Data models (Project, Task, Comment)
│   ├── repositories/           # Repositories (Auth, Project, Task)
│   └── services/               # Git services (REST API, libgit2)
├── injection/                  # Dependency injection
├── l10n/                       # Локализация (ARB файлы)
└── presentation/
    ├── providers/              # Riverpod providers
    ├── screens/                # Экраны (auth, projects, tasks)
    └── widgets/                # Переиспользуемые виджеты
```

## 📱 Экраны приложения

| Экран | Описание |
|-------|----------|
| **Auth** | Выбор Git-сервера и вход по токену |
| **Projects** | Список репозиториев пользователя |
| **Task List** | Задачи проекта с фильтрацией по номеру и названию |
| **Task Detail** | Просмотр и редактирование задачи |
| **Sync** | Статус синхронизации с удалённым репозиторием |

## 🌍 Локализация

Поддерживаемые языки:

- 🇬🇧 English
- 🇷🇺 Русский

Язык автоматически определяется из настроек устройства. Для добавления нового языка:

1. Добавьте ключи в `lib/l10n/arb/app_en.arb`
2. Создайте `app_<lang>.arb`
3. Запустите `flutter pub get`

## 📝 Разработка

### Генерация кода

```bash
# Freezed, JSON, Riverpod
flutter pub run build_runner build --delete-conflicting-outputs
```

### Тесты

```bash
# Все тесты
flutter test

# С покрытием
flutter test --coverage
```

### Линтинг

```bash
flutter analyze
```

## 📄 Лицензия

[Добавьте лицензию]

## 🤝 Вклад

Приветствуется! Открывайте issues и pull requests.

---

**Сделано с ❤️ на Flutter**
