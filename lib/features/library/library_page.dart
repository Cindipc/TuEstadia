import 'package:flutter/material.dart';

import '../../app_theme.dart';
import 'drive_library_controller.dart';
import 'drive_library_view.dart';

/// Pantalla "Biblioteca": proyectos almacenados en Google Drive.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.onBack});

  /// Callback ejecutado al pulsar la flecha de retroceso.
  final VoidCallback? onBack;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late final DriveLibraryController _driveController;

  @override
  void initState() {
    super.initState();
    _driveController = DriveLibraryController();
  }

  @override
  void dispose() {
    _driveController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_driveController.canGoBack) {
      _driveController.goBack();
      return;
    }

    final navigator = Navigator.of(context);
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neoBackground,
      appBar: AppBar(
        backgroundColor: AppColors.neoBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: _handleBack,
        ),
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar proyectos',
            color: AppColors.neoCyan,
            onPressed: _driveController.refresh,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_copy_rounded,
                    color: AppColors.neoCyan,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Proyectos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: DriveLibraryView(controller: _driveController)),
          ],
        ),
      ),
    );
  }
}
