import 'dart:io';

/// Lee una variable desde el `.env` de la carpeta del proyecto.
///
/// Es un respaldo para desarrollo: si el asset `.env` no viaja en el bundle
/// (por ejemplo en web), en desktop/móvil se lee el archivo local.
String? readLocalEnvValue(String key) {
  try {
    final file = File('.env');
    if (!file.existsSync()) return null;
    return parseEnvValue(file.readAsStringSync(), key);
  } catch (_) {
    return null;
  }
}

/// Parser mínimo de `.env` (KEY=valor, comentarios con # y comillas).
String? parseEnvValue(String contents, String key) {
  for (final rawLine in contents.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final separator = line.indexOf('=');
    if (separator <= 0) continue;

    final name = line.substring(0, separator).trim();
    if (name != key) continue;

    var value = line.substring(separator + 1).trim();
    if (value.length >= 2) {
      final quoted =
          (value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"));
      if (quoted) value = value.substring(1, value.length - 1);
    }
    return value.trim().isEmpty ? null : value.trim();
  }
  return null;
}
