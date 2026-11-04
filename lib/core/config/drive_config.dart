/// Configuración de Google Drive leída en tiempo de compilación.
///
/// Los valores se pasan con `--dart-define` y nunca se versionan.
class DriveConfig {
  DriveConfig._();

  static const String apiKey = String.fromEnvironment('GOOGLE_DRIVE_API_KEY');
  static const String rootFolderId = String.fromEnvironment(
    'GOOGLE_DRIVE_FOLDER_ID',
  );

  static bool get isConfigured =>
      apiKey.trim().isNotEmpty && rootFolderId.trim().isNotEmpty;
}
