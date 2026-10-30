// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Commitly';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get noProjectsFound => 'No projects found';

  @override
  String get addRepository => 'Add a repository to get started';

  @override
  String get addProject => 'Add Project';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get refresh => 'Refresh';

  @override
  String get authSelectionTitle => 'Git Service';

  @override
  String get authSelectionGitHub => 'GitHub';

  @override
  String get authSelectionGitHubDesc => 'GitHub.com or Enterprise';

  @override
  String get authSelectionGitLab => 'GitLab';

  @override
  String get authSelectionGitLabDesc => 'GitLab.com or self-hosted';

  @override
  String get authSelectionGitea => 'Gitea';

  @override
  String get authSelectionGiteaDesc => 'Gitea or Gitverse';

  @override
  String get authSelectionCustom => 'Custom';

  @override
  String get authSelectionCustomDesc => 'Other Git service';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get baseUrlHint => 'https://api.github.com';

  @override
  String get personalAccessToken => 'Personal Access Token';

  @override
  String get patHint => 'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting...';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String taskListTitle(Object projectName) {
    return 'Tasks: $projectName';
  }

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get newTask => 'New Task';

  @override
  String get searchByTitle => 'Search by title...';

  @override
  String get filterNumber => '# Number';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get noTasksMatchFilters => 'No tasks match filters';

  @override
  String taskDetailTitle(Object taskNumber) {
    return 'Task #$taskNumber';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get metadata => 'Metadata';

  @override
  String get title => 'Title';

  @override
  String get titleHint => 'Task title';

  @override
  String get assignee => 'Assignee';

  @override
  String get assigneeHint => 'Username';

  @override
  String get addTag => 'Add Tag';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Enter description (Markdown supported)';

  @override
  String get noDescriptionYet => 'No description yet';

  @override
  String get attachments => 'Attachments';

  @override
  String get noAttachmentsYet => 'No attachments yet';

  @override
  String get uploadFile => 'Upload File';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get writeComment => 'Write a comment (Markdown supported)...';

  @override
  String get send => 'Send';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(Object count) {
    return '${count}d ago';
  }

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get invalidTaskNumber => 'Invalid task number';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncSuccess => 'All changes pushed';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get pulling => 'Pulling changes...';

  @override
  String get pullSuccess => 'Up to date';

  @override
  String get pullFailed => 'Pull failed';

  @override
  String get taskSaved => 'Task saved';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get assigneeUpdated => 'Assignee updated';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get titleUpdated => 'Title updated';

  @override
  String get descriptionSaved => 'Description saved';

  @override
  String get projectsLabel => 'Projects';

  @override
  String get tasksLabel => 'Tasks';

  @override
  String get syncLabel => 'Sync';

  @override
  String get projectSettings => 'Project Settings';

  @override
  String get projectName => 'Project Name';

  @override
  String get projectNameHint => 'Enter project name';

  @override
  String get projectNameDescription =>
      'This name will be displayed in the app. It is saved in metadata.json in the repository root.';

  @override
  String get projectNameSaved => 'Project name saved';

  @override
  String failedCreateTask(Object error) {
    return 'Failed to create task: $error';
  }

  @override
  String failedSendComment(Object error) {
    return 'Failed to send comment: $error';
  }
}
