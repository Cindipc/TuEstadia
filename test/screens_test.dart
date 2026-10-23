import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_estadia/app_theme.dart';
import 'package:tu_estadia/features/feed/home_page.dart';
import 'package:tu_estadia/features/forum/forum_page.dart';
import 'package:tu_estadia/features/library/library_page.dart';
import 'package:tu_estadia/features/shell/main_shell.dart';
import 'package:tu_estadia/login_page.dart';
import 'package:tu_estadia/main.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.neoDark,
    darkTheme: AppTheme.neoDark,
    themeMode: ThemeMode.dark,
    home: child,
  );
}

void main() {
  testWidgets('La app arranca en modo demo y muestra el login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TuEstadiaApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('TuEstadia'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Explorar en modo demo'), findsOneWidget);

    await tester.ensureVisible(find.text('Explorar en modo demo'));
    await tester.tap(find.text('Explorar en modo demo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Entra al shell principal
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Biblioteca'), findsWidgets);
  });

  testWidgets('Login: los campos y validaciones funcionan', (tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const LoginPage()));
    await tester.pump();

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);

    // Enviar vacío debe mostrar los errores de validación
    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(find.text('El correo electrónico es obligatorio.'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria.'), findsOneWidget);
  });

  testWidgets('Home - Feed: muestra barra de búsqueda, chips y tarjetas', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const HomePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Top bar
    expect(find.text('Search'), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);

    // Chips de categorías
    expect(find.text('Home - Feed'), findsOneWidget);
    expect(find.text('Flutter'), findsWidgets);

    // Tarjetas del feed
    expect(find.text('UI Clone in Flutter'), findsOneWidget);
    expect(find.text('Save'), findsWidgets);
    expect(find.byIcon(Icons.bookmark_border), findsWidgets);
  });

  testWidgets('Home - Feed: el filtro por categoría reduce las tarjetas', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const HomePage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('UI Clone in Flutter'), findsOneWidget);

    await tester.tap(find.text('Python').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('UI Clone in Flutter'), findsNothing);
    expect(find.text('Bot de Discord en Python'), findsOneWidget);
  });

  testWidgets('Biblioteca: carrusel de cursos y línea de tiempo', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const LibraryPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsOneWidget);

    // Carrusel superior
    expect(find.text('Python desde Cero'), findsWidgets);

    // Sección de capítulos
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Chapter: 1'), findsWidgets);
    expect(find.text('Continuar leyendo'), findsWidgets);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Foro de Dudas: posts, código y barra de acciones', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const ForumPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Foro de Dudas'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

    expect(find.text('Error de sintaxis en bucle For?'), findsOneWidget);
    expect(find.textContaining('Carla Méndez'), findsWidgets);
    expect(find.textContaining('Responder'), findsWidgets);
    expect(find.textContaining('Like'), findsWidgets);
    expect(find.textContaining('Guardar'), findsWidgets);
  });

  testWidgets('Shell: la navegación inferior cambia de pestaña', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MainShell()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Pestaña inicial: Feed
    expect(find.text('Search'), findsOneWidget);

    await tester.tap(find.text('Biblioteca'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Chapters'), findsOneWidget);

    await tester.tap(find.text('Foro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Foro de Dudas'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Proyectos'), findsOneWidget);
  });

  testWidgets('Las tres pantallas caben en un móvil de 360px', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final page in <Widget>[
      const HomePage(),
      const LibraryPage(),
      const ForumPage(),
    ]) {
      await tester.pumpWidget(wrap(page));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Si hubiera un RenderFlex desbordado, el test fallaría aquí.
      expect(tester.takeException(), isNull);
    }
  });
}
