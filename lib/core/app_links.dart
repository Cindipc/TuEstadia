import 'package:url_launcher/url_launcher.dart';

/// Enlaces legales y de soporte de la app.
///
/// Se publican desde la carpeta `docs/` con Firebase Hosting.
/// Si cambias de dominio, actualiza estas constantes y la ficha de Play.
class AppLinks {
  AppLinks._();

  static const String privacyPolicy =
      'https://fwitter-7596d.web.app/privacy-policy.html';
  static const String terms = 'https://fwitter-7596d.web.app/terms.html';
  static const String accountDeletion =
      'https://fwitter-7596d.web.app/account-deletion.html';
  static const String support = 'https://github.com/Cindipc/TuEstadia/issues';
}

Future<bool> openAppLink(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
