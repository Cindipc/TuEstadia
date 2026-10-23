import 'models/chapter.dart';
import 'models/course.dart';
import 'models/forum_post.dart';
import 'models/project.dart';

/// Datos de prueba que alimentan la app cuando Firebase no está configurado
/// o cuando una consulta a Firestore falla.
class DemoData {
  DemoData._();

  static String _avatar(int seed) => 'https://i.pravatar.cc/120?img=$seed';

  static String _cover(String seed) =>
      'https://picsum.photos/seed/$seed/480/320';

  static final List<ProjectModel> projects = List.generate(12, (index) {
    const titles = [
      'UI Clone in Flutter',
      'API REST con Node',
      'Dashboard analítico',
      'Chat en tiempo real',
      'Portfolio dev',
      'Juego de plataformas 2D',
      'CRUD con Firebase',
      'Landing page animada',
      'Task manager offline',
      'Weather app responsive',
      'E-commerce con carrito',
      'Bot de Discord en Python',
    ];
    const techs = [
      'Flutter',
      'Node.js',
      'React',
      'Firebase',
      'Flutter',
      'Python',
      'Firebase',
      'CSS',
      'Flutter',
      'Dart',
      'Kotlin',
      'Python',
    ];
    const authors = [
      'Carla Méndez',
      'Iván Rojas',
      'Sofía_ALIGN',
      'Diego Salas',
      'Lucía Peña',
      'Mateo Cruz',
      'Valeria Ortiz',
      'Tomás Lara',
      'Renata Gil',
      'Bruno Paz',
      'Camila Duarte',
      'Emilio Vega',
    ];

    return ProjectModel(
      id: 'demo-project-$index',
      title: titles[index],
      tech: techs[index],
      imageUrl: _cover('tu-estadia-$index'),
      authorName: authors[index],
      authorAvatar: _avatar(index + 10),
      saved: index % 4 == 0,
      createdAt: DateTime.now().subtract(Duration(hours: index * 7)),
    );
  });

  static final List<CourseModel> courses = [
    const CourseModel(
      id: 'demo-course-1',
      title: 'Python desde Cero',
      subtitle: '12 capítulos · 4h 30m',
      iconKey: 'python',
      colorValue: 0xFF38BDF8,
      gradientStart: 0xFF0EA5E9,
      gradientEnd: 0xFF6366F1,
    ),
    const CourseModel(
      id: 'demo-course-2',
      title: 'Flutter Avanzado',
      subtitle: '18 capítulos · 9h 10m',
      iconKey: 'flutter',
      colorValue: 0xFF34D399,
      gradientStart: 0xFF10B981,
      gradientEnd: 0xFF0EA5E9,
    ),
    const CourseModel(
      id: 'demo-course-3',
      title: 'Bases de Datos SQL',
      subtitle: '10 capítulos · 3h 45m',
      iconKey: 'database',
      colorValue: 0xFFA78BFA,
      gradientStart: 0xFF8B5CF6,
      gradientEnd: 0xFFEC4899,
    ),
    const CourseModel(
      id: 'demo-course-4',
      title: 'Git & GitHub',
      subtitle: '8 capítulos · 2h 20m',
      iconKey: 'git',
      colorValue: 0xFFFBBF24,
      gradientStart: 0xFFF59E0B,
      gradientEnd: 0xFFEF4444,
    ),
    const CourseModel(
      id: 'demo-course-5',
      title: 'Algoritmos y Estructuras',
      subtitle: '22 capítulos · 12h 05m',
      iconKey: 'algorithm',
      colorValue: 0xFFF472B6,
      gradientStart: 0xFFEC4899,
      gradientEnd: 0xFF8B5CF6,
    ),
  ];

  static final List<ChapterModel> chapters = [
    ChapterModel(
      id: 'demo-chapter-1',
      courseId: 'demo-course-1',
      title: 'Python desde Cero',
      chapterNumber: 1,
      progress: 1,
    ),
    ChapterModel(
      id: 'demo-chapter-2',
      courseId: 'demo-course-1',
      title: 'Python desde Cero',
      chapterNumber: 2,
      progress: 0.75,
    ),
    ChapterModel(
      id: 'demo-chapter-3',
      courseId: 'demo-course-2',
      title: 'Flutter Avanzado',
      chapterNumber: 1,
      progress: 0.4,
    ),
    ChapterModel(
      id: 'demo-chapter-4',
      courseId: 'demo-course-3',
      title: 'Bases de Datos SQL',
      chapterNumber: 3,
      progress: 0.2,
    ),
    ChapterModel(
      id: 'demo-chapter-5',
      courseId: 'demo-course-5',
      title: 'Algoritmos y Estructuras',
      chapterNumber: 7,
      progress: 0.55,
    ),
  ];

  static final List<ForumPostModel> posts = [
    ForumPostModel(
      id: 'demo-post-1',
      authorName: 'Carla Méndez',
      authorAvatar: _avatar(12),
      question: 'Error de sintaxis en bucle For?',
      code: '''for (int i = 0; i < 10; i++) {
  if (i % 2 == 0) {
    print("Numero par: \$i");
  }
}''',
      likes: 24,
      replies: 6,
      saved: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 129)),
    ),
    ForumPostModel(
      id: 'demo-post-2',
      authorName: 'Iván Rojas',
      authorAvatar: _avatar(16),
      question:
          '¿Cómo estructuro un FutureBuilder para cargar datos de Firestore sin parpadeos?',
      code: '''FutureBuilder<List<User>>(
  future: FirebaseFirestore.instance.collection("users").get(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (_, i) => UserTile(user: snapshot.data![i]),
    );
  },
)''',
      likes: 41,
      replies: 12,
      saved: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ForumPostModel(
      id: 'demo-post-3',
      authorName: 'Sofía Alvarez',
      authorAvatar: _avatar(19),
      question:
          '¿Por qué mi widget no se redibuja al cambiar una variable dentro de un StreamBuilder?',
      code: '''class _CounterState extends State<Counter> {
  int _value = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _value++),
      child: Text("Valor: \$_value"),
    );
  }
}''',
      likes: 12,
      replies: 3,
      saved: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    ForumPostModel(
      id: 'demo-post-4',
      authorName: 'Diego Salas',
      authorAvatar: _avatar(22),
      question: 'Buenas prácticas para modelar esta respuesta JSON en Dart',
      code: '''class ApiResponse {
  final int code;
  final List<String> tags;

  const ApiResponse({required this.code, required this.tags});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      code: json["code"] as int,
      tags: (json["tags"] as List).cast<String>(),
    );
  }
}''',
      likes: 33,
      replies: 9,
      saved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];
}
