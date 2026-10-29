/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// Repository structure paths
  static const tasksPath = 'tasks';
  static const commentsPath = 'comments';
  static const attachmentsPath = 'attachments';
  static const configPath = '.commitly/config.json';

  /// Task folder zero-padding width
  static const int taskFolderPadding = 3;

  /// Default branch name
  static const defaultBranch = 'main';

  /// Committer info
  static const committerName = 'Commitly';
  static const committerEmail = 'commitly@openitstudio.com';

  /// Storage keys
  static const keyServiceConfig = 'git_service_config';
  static const keyPersonalAccessToken = 'git_pat';
}
