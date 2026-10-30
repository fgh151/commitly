// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Commitly';

  @override
  String get projectsTitle => 'Проекты';

  @override
  String get noProjectsFound => 'Проекты не найдены';

  @override
  String get addRepository => 'Добавьте репозиторий для начала работы';

  @override
  String get addProject => 'Добавить проект';

  @override
  String get disconnect => 'Отключиться';

  @override
  String get refresh => 'Обновить';

  @override
  String get authSelectionTitle => 'Git-сервис';

  @override
  String get authSelectionGitHub => 'GitHub';

  @override
  String get authSelectionGitHubDesc => 'GitHub.com или Enterprise';

  @override
  String get authSelectionGitLab => 'GitLab';

  @override
  String get authSelectionGitLabDesc => 'GitLab.com или self-hosted';

  @override
  String get authSelectionGitea => 'Gitea';

  @override
  String get authSelectionGiteaDesc => 'Gitea или Gitverse';

  @override
  String get authSelectionCustom => 'Другой';

  @override
  String get authSelectionCustomDesc => 'Другой Git-сервис';

  @override
  String get baseUrl => 'Базовый URL';

  @override
  String get baseUrlHint => 'https://api.github.com';

  @override
  String get personalAccessToken => 'Персональный токен (PAT)';

  @override
  String get patHint => 'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  @override
  String get connect => 'Подключиться';

  @override
  String get connecting => 'Подключение...';

  @override
  String get invalidCredentials => 'Неверные учётные данные';

  @override
  String get connectionFailed => 'Ошибка подключения';

  @override
  String taskListTitle(Object projectName) {
    return 'Задачи: $projectName';
  }

  @override
  String get noTasksYet => 'Задач пока нет';

  @override
  String get newTask => 'Новая задача';

  @override
  String get searchByTitle => 'Поиск по названию...';

  @override
  String get filterNumber => '# Номер';

  @override
  String get clearFilters => 'Очистить фильтры';

  @override
  String get noTasksMatchFilters => 'Нет задач по фильтру';

  @override
  String taskDetailTitle(Object taskNumber) {
    return 'Задача #$taskNumber';
  }

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get edit => 'Изменить';

  @override
  String get metadata => 'Метаданные';

  @override
  String get title => 'Название';

  @override
  String get titleHint => 'Название задачи';

  @override
  String get assignee => 'Исполнитель';

  @override
  String get assigneeHint => 'Имя пользователя';

  @override
  String get addTag => 'Добавить тег';

  @override
  String get description => 'Описание';

  @override
  String get descriptionHint => 'Введите описание (поддерживается Markdown)';

  @override
  String get noDescriptionYet => 'Описание пока нет';

  @override
  String get attachments => 'Вложения';

  @override
  String get noAttachmentsYet => 'Вложений пока нет';

  @override
  String get uploadFile => 'Загрузить файл';

  @override
  String get comments => 'Комментарии';

  @override
  String get noCommentsYet => 'Комментариев пока нет';

  @override
  String get writeComment => 'Напишите комментарий (поддерживается Markdown)...';

  @override
  String get send => 'Отправить';

  @override
  String get justNow => 'только что';

  @override
  String minutesAgo(Object count) {
    return '$count мин. назад';
  }

  @override
  String hoursAgo(Object count) {
    return '$count ч. назад';
  }

  @override
  String daysAgo(Object count) {
    return '$count дн. назад';
  }

  @override
  String get pageNotFound => 'Страница не найдена';

  @override
  String get invalidTaskNumber => 'Неверный номер задачи';

  @override
  String get syncing => 'Синхронизация...';

  @override
  String get syncSuccess => 'Все изменения отправлены';

  @override
  String get syncFailed => 'Ошибка синхронизации';

  @override
  String get pulling => 'Получение изменений...';

  @override
  String get pullSuccess => 'Актуально';

  @override
  String get pullFailed => 'Ошибка получения';

  @override
  String get taskSaved => 'Задача сохранена';

  @override
  String get saveFailed => 'Ошибка сохранения';

  @override
  String get assigneeUpdated => 'Исполнитель обновлён';

  @override
  String get updateFailed => 'Ошибка обновления';

  @override
  String get titleUpdated => 'Название обновлено';

  @override
  String get descriptionSaved => 'Описание сохранено';

  @override
  String get projectsLabel => 'Проекты';

  @override
  String get tasksLabel => 'Задачи';

  @override
  String get syncLabel => 'Синхронизация';

  @override
  String get projectSettings => 'Настройки проекта';

  @override
  String get projectName => 'Название проекта';

  @override
  String get projectNameHint => 'Введите название проекта';

  @override
  String get projectNameDescription =>
      'Это название будет отображаться в приложении. Оно сохраняется в metadata.json в корне репозитория.';

  @override
  String get projectNameSaved => 'Название проекта сохранено';

  @override
  String failedCreateTask(Object error) {
    return 'Не удалось создать задачу: $error';
  }

  @override
  String failedSendComment(Object error) {
    return 'Не удалось отправить комментарий: $error';
  }
}
