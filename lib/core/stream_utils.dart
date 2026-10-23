import 'dart:async';

/// Convierte un error de un stream en un valor de respaldo, de modo que la UI
/// nunca se quede en blanco si Firestore falla (permisos, sin red, proyecto
/// inexistente, etc.).
Stream<T> withFallback<T>(Stream<T> source, T fallback) {
  return source.transform(
    StreamTransformer<T, T>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stackTrace, sink) => sink.add(fallback),
    ),
  );
}
