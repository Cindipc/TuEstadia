import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_theme.dart';
import '../../core/repositories/pin_repository.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  static const _techs = [
    'Flutter',
    'Node.js',
    'React',
    'Firebase',
    'Python',
    'Kotlin',
    'CSS',
  ];

  final _repo = PinRepository();
  final _picker = ImagePicker();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String _imageName = 'pin.jpg';
  String _tech = 'Flutter';
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = picked.name.isNotEmpty ? picked.name : 'pin.jpg';
    });
  }

  Future<void> _publish() async {
    if (_saving) return;
    if (_imageBytes == null) return _toast('Elige una imagen');
    if (_titleCtrl.text.trim().isEmpty) return _toast('Escribe un título');

    setState(() => _saving = true);
    try {
      await _repo.createPin(
        imageBytes: _imageBytes!,
        fileName: _imageName,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        tech: _tech,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('No se pudo publicar: $e');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.neoTextMuted),
        filled: true,
        fillColor: AppColors.neoSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neoBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neoBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neoCyan),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        title: const Text('Crear pin'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _publish,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Publicar',
                      style: TextStyle(
                        color: AppColors.neoCyan,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neoSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.neoBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 44, color: AppColors.neoCyan),
                          SizedBox(height: 10),
                          Text('Toca para elegir una imagen',
                              style: TextStyle(color: AppColors.neoTextMuted)),
                        ],
                      )
                    : Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _titleCtrl,
            maxLength: 80,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Título'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Descripción'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _techs)
                ChoiceChip(
                  label: Text(t),
                  selected: _tech == t,
                  onSelected: (_) => setState(() => _tech = t),
                ),
            ],
          ),
        ],
      ),
    );
  }
}