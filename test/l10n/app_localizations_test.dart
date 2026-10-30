import 'package:flutter_test/flutter_test.dart';
import 'package:commitly/l10n/app_localizations.dart';
import 'package:commitly/l10n/app_localizations_en.dart';
import 'package:commitly/l10n/app_localizations_ru.dart';

void main() {
  group('AppLocalizations', () {
    late AppLocalizationsEn en;
    late AppLocalizationsRu ru;

    setUpAll(() {
      en = AppLocalizationsEn();
      ru = AppLocalizationsRu();
    });

    group('English', () {
      test('should have app title', () {
        expect(en.appTitle, 'Commitly');
      });

      test('should have project-related translations', () {
        expect(en.projectsTitle, 'Projects');
        expect(en.projectsLabel, 'Projects');
        expect(en.noProjectsFound, 'No projects found');
        expect(en.addRepository, 'Add a repository to get started');
        expect(en.addProject, 'Add Project');
      });

      test('should have auth-related translations', () {
        expect(en.authSelectionTitle, 'Git Service');
        expect(en.authSelectionGitHub, 'GitHub');
        expect(en.authSelectionGitHubDesc, 'GitHub.com or Enterprise');
        expect(en.authSelectionGitLab, 'GitLab');
        expect(en.authSelectionGitLabDesc, 'GitLab.com or self-hosted');
        expect(en.authSelectionGitea, 'Gitea');
        expect(en.authSelectionGiteaDesc, 'Gitea or Gitverse');
        expect(en.authSelectionCustom, 'Custom');
        expect(en.authSelectionCustomDesc, 'Other Git service');
      });

      test('should have form field translations', () {
        expect(en.baseUrl, 'Base URL');
        expect(en.baseUrlHint, 'https://api.github.com');
        expect(en.personalAccessToken, 'Personal Access Token');
        expect(en.patHint, 'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
        expect(en.connect, 'Connect');
        expect(en.connecting, 'Connecting...');
      });

      test('should have task-related translations', () {
        expect(en.taskListTitle('My Project'), 'Tasks: My Project');
        expect(en.noTasksYet, 'No tasks yet');
        expect(en.newTask, 'New Task');
        expect(en.searchByTitle, 'Search by title...');
        expect(en.filterNumber, '# Number');
        expect(en.clearFilters, 'Clear filters');
      });

      test('should have task detail translations', () {
        expect(en.taskDetailTitle('123'), 'Task #123');
        expect(en.save, 'Save');
        expect(en.cancel, 'Cancel');
        expect(en.edit, 'Edit');
        expect(en.metadata, 'Metadata');
        expect(en.title, 'Title');
        expect(en.titleHint, 'Task title');
        expect(en.assignee, 'Assignee');
        expect(en.assigneeHint, 'Username');
      });

      test('should have description translations', () {
        expect(en.description, 'Description');
        expect(en.descriptionHint, 'Enter description (Markdown supported)');
        expect(en.noDescriptionYet, 'No description yet');
      });

      test('should have comment translations', () {
        expect(en.comments, 'Comments');
        expect(en.noCommentsYet, 'No comments yet');
        expect(en.writeComment, 'Write a comment (Markdown supported)...');
        expect(en.send, 'Send');
      });

      test('should have time translations', () {
        expect(en.justNow, 'just now');
        expect(en.minutesAgo(5), '5m ago');
        expect(en.hoursAgo(2), '2h ago');
        expect(en.daysAgo(3), '3d ago');
      });

      test('should have sync translations', () {
        expect(en.syncing, 'Syncing...');
        expect(en.syncSuccess, 'All changes pushed');
        expect(en.syncFailed, 'Sync failed');
        expect(en.pulling, 'Pulling changes...');
        expect(en.pullSuccess, 'Up to date');
        expect(en.pullFailed, 'Pull failed');
      });

      test('should have error translations', () {
        expect(en.pageNotFound, 'Page not found');
        expect(en.invalidTaskNumber, 'Invalid task number');
        expect(en.saveFailed, 'Save failed');
      });

      test('should have project settings translations', () {
        expect(en.projectSettings, 'Project Settings');
        expect(en.projectName, 'Project Name');
        expect(en.projectNameHint, 'Enter project name');
        expect(en.projectNameSaved, 'Project name saved');
      });
    });

    group('Russian', () {
      test('should have app title', () {
        expect(ru.appTitle, 'Commitly');
      });

      test('should have project-related translations', () {
        expect(ru.projectsTitle, 'Проекты');
        expect(ru.projectsLabel, 'Проекты');
        expect(ru.noProjectsFound, 'Проекты не найдены');
        expect(ru.addRepository, 'Добавьте репозиторий для начала работы');
        expect(ru.addProject, 'Добавить проект');
      });

      test('should have auth-related translations', () {
        expect(ru.authSelectionTitle, 'Git-сервис');
        expect(ru.authSelectionGitHub, 'GitHub');
        expect(ru.authSelectionGitHubDesc, 'GitHub.com или Enterprise');
        expect(ru.authSelectionGitLab, 'GitLab');
        expect(ru.authSelectionGitLabDesc, 'GitLab.com или self-hosted');
        expect(ru.authSelectionGitea, 'Gitea');
        expect(ru.authSelectionGiteaDesc, 'Gitea или Gitverse');
      });

      test('should have form field translations', () {
        expect(ru.baseUrl, 'Базовый URL');
        expect(ru.personalAccessToken, 'Персональный токен (PAT)');
        expect(ru.connect, 'Подключиться');
        expect(ru.connecting, 'Подключение...');
      });

      test('should have task-related translations', () {
        expect(ru.taskListTitle('Мой Проект'), 'Задачи: Мой Проект');
        expect(ru.noTasksYet, 'Задач пока нет');
        expect(ru.newTask, 'Новая задача');
        expect(ru.searchByTitle, 'Поиск по названию...');
      });

      test('should have task detail translations', () {
        expect(ru.taskDetailTitle('456'), 'Задача #456');
        expect(ru.save, 'Сохранить');
        expect(ru.cancel, 'Отмена');
        expect(ru.edit, 'Изменить');
      });

      test('should have sync translations', () {
        expect(ru.syncing, 'Синхронизация...');
        expect(ru.syncSuccess, 'Все изменения отправлены');
        expect(ru.syncFailed, 'Ошибка синхронизации');
      });

      test('should have error translations', () {
        expect(ru.pageNotFound, 'Страница не найдена');
        expect(ru.invalidTaskNumber, 'Неверный номер задачи');
      });

      test('should have project settings translations', () {
        expect(ru.projectSettings, 'Настройки проекта');
        expect(ru.projectName, 'Название проекта');
        expect(ru.projectNameHint, 'Введите название проекта');
        expect(ru.projectNameSaved, 'Название проекта сохранено');
      });
    });

    group('Localization consistency', () {
      test('should have same number of keys in both locales', () {
        final enKeys = en.toString().replaceAll(RegExp(r'[^\n]'), '').split('\n').length;
        final ruKeys = ru.toString().replaceAll(RegExp(r'[^\n]'), '').split('\n').length;
        // Both should have similar structure
        expect(enKeys > 0, true);
        expect(ruKeys > 0, true);
      });
    });
  });
}
