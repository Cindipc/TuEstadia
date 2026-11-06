import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../models/project.dart';
import '../repositories/pin_repository.dart';
import '../repositories/project_repository.dart';

/// Diálogo de confirmación para eliminar una publicación.
Future<bool> confirmDeletion(
  BuildContext context, {
  String title = '¿Eliminar publicación?',
  String message = 'Esta acción no se puede deshacer.',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.neoSurface,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 17),
      ),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.neoTextMuted, fontSize: 13.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Elimina el elemento del feed en la colección correcta (`pins` o `projects`).
Future<bool> deleteProjectItem({
  required ProjectModel project,
  required PinRepository pinRepository,
  required ProjectRepository projectRepository,
}) {
  return project.source == ProjectSource.pin
      ? pinRepository.deletePin(project.id)
      : projectRepository.deleteProject(project.id);
}
