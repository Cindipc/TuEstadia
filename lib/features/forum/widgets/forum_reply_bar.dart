import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../core/auth_service.dart';
import '../../../core/widgets/app_avatar.dart';

/// Barra inferior para responder dentro de un hilo.
///
/// [onSend] devuelve `true` si la respuesta se guardó; solo entonces se limpia
/// el campo (si falla, el texto se conserva para reintentar).
class ForumReplyBar extends StatefulWidget {
  const ForumReplyBar({
    super.key,
    required this.onSend,
    required this.onExpand,
    this.hint = 'Escribe una respuesta…',
    this.focusNode,
  });

  final Future<bool> Function(String text) onSend;
  final VoidCallback onExpand;
  final String hint;
  final FocusNode? focusNode;

  @override
  State<ForumReplyBar> createState() => _ForumReplyBarState();
}

class _ForumReplyBarState extends State<ForumReplyBar> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final ok = await widget.onSend(text);
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neoSurface,
        border: Border(top: BorderSide(color: AppColors.neoBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AppAvatar(
                  imageUrl: AuthService.photoUrl ?? '',
                  name: AuthService.displayName,
                  size: 32,
                  borderColor: AppColors.neoCyan.withValues(alpha: 0.5),
                  borderWidth: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: AppColors.neoCyan,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      color: AppColors.neoTextMuted,
                      fontSize: 13.5,
                    ),
                    filled: true,
                    fillColor: AppColors.neoSurfaceAlt,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.neoBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.neoBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.neoCyan,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Ampliar',
                onPressed: widget.onExpand,
                icon: const Icon(
                  Icons.open_in_full,
                  size: 18,
                  color: AppColors.neoTextMuted,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  final canSend = value.text.trim().isNotEmpty && !_sending;
                  return IconButton.filled(
                    tooltip: 'Enviar respuesta',
                    onPressed: canSend ? _send : null,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.neoCyan,
                      foregroundColor: AppColors.onCyan,
                      disabledBackgroundColor: AppColors.neoBorder,
                      disabledForegroundColor: AppColors.neoTextMuted,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onCyan,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
