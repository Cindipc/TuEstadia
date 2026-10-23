import 'package:flutter/material.dart';

import '../../../app_theme.dart';

/// Bloque de código con resaltado de sintaxis básico.
///
/// Se tokeniza el código con una única expresión regular y se colorean:
/// comentarios, cadenas, números, palabras reservadas y llamadas a función.
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.maxHeight = 220});

  final String code;
  final double maxHeight;

  static const TextStyle _baseStyle = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Consolas', 'Courier New'],
    fontSize: 12.5,
    height: 1.5,
    color: Color(0xFFCBD5E1),
  );

  static const Set<String> _keywords = {
    'abstract', 'async', 'await', 'break', 'case', 'catch', 'class', 'const',
    'continue', 'def', 'default', 'do', 'else', 'enum', 'export', 'extends',
    'false', 'final', 'finally', 'for', 'from', 'function', 'if', 'implements',
    'import', 'in', 'instanceof', 'let', 'new', 'null', 'of', 'print',
    'private', 'public', 'return', 'static', 'super', 'switch', 'this',
    'throw', 'true', 'try', 'typeof', 'var', 'void', 'while', 'with', 'yield',
    'int', 'double', 'bool', 'String', 'List', 'Map', 'Future', 'Widget',
    'State', 'BuildContext', 'setState', 'console',
  };

  static final RegExp _tokenPattern = RegExp(
    r'''(//[^\n]*|/\*[\s\S]*?\*/)'''
    r'''|("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)'''
    r'''|(\b\d+(?:\.\d+)?\b)'''
    r'''|\b([A-Za-z_][A-Za-z0-9_]*)\b'''
    r'''|([{}()\[\];,.:=<>!+\-*/%&|?]+)''',
    multiLine: true,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.neoSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neoBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: SelectableText.rich(
            TextSpan(children: _highlight(code)),
            style: _baseStyle,
          ),
        ),
      ),
    );
  }

  static List<TextSpan> _highlight(String source) {
    final spans = <TextSpan>[];
    var index = 0;

    for (final match in _tokenPattern.allMatches(source)) {
      if (match.start > index) {
        spans.add(TextSpan(text: source.substring(index, match.start)));
      }

      final comment = match.group(1);
      final string = match.group(2);
      final number = match.group(3);
      final word = match.group(4);
      final operator = match.group(5);

      if (comment != null) {
        spans.add(
          TextSpan(
            text: comment,
            style: const TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),
        );
      } else if (string != null) {
        spans.add(
          TextSpan(
            text: string,
            style: const TextStyle(color: Color(0xFF34D399)),
          ),
        );
      } else if (number != null) {
        spans.add(
          TextSpan(
            text: number,
            style: const TextStyle(color: Color(0xFFFBBF24)),
          ),
        );
      } else if (word != null) {
        final isKeyword = _keywords.contains(word);
        final isCall = _isFunctionCall(source, match.end);
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(
              color: isKeyword
                  ? const Color(0xFFC084FC)
                  : isCall
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFE2E8F0),
              fontWeight: isKeyword || isCall
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        );
      } else if (operator != null) {
        spans.add(
          TextSpan(
            text: operator,
            style: const TextStyle(color: Color(0xFFF472B6)),
          ),
        );
      }

      index = match.end;
    }

    if (index < source.length) {
      spans.add(TextSpan(text: source.substring(index)));
    }

    return spans;
  }

  static bool _isFunctionCall(String source, int end) {
    var cursor = end;
    while (cursor < source.length && source[cursor] == ' ') {
      cursor++;
    }
    return cursor < source.length && source[cursor] == '(';
  }
}
