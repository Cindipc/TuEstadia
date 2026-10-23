import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../core/repositories/forum_repository.dart';

/// Pantalla para crear una publicación en el foro.
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final ForumRepository _repository = ForumRepository();

  bool _sending = false;

  @override
  void dispose() {
    _questionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Escribe tu pregunta antes de publicar.')),
        );
      return;
    }

    setState(() => _sending = true);
    await _repository.createPost(
      question: question,
      code: _codeController.text.trim(),
      authorName: 'Tu Estadia',
      authorAvatar: 'https://i.pravatar.cc/120?img=45',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        title: const Text('Nueva publicación'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            const Text(
              'Pregunta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              cursorColor: AppColors.neoCyan,
              decoration: const InputDecoration(
                hintText: '¿Cuál es tu duda?',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Código (opcional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              maxLines: 8,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.5,
              ),
              cursorColor: AppColors.neoCyan,
              decoration: const InputDecoration(
                hintText: 'Pega aquí el fragmento de código',
                hintStyle: TextStyle(
                  color: AppColors.neoTextMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: _sending ? null : _publish,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.neoCyan,
                foregroundColor: const Color(0xFF06232E),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF06232E),
                      ),
                    )
                  : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
