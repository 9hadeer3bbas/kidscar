class Failure {
  const Failure({
    required this.message,
    this.code,
    this.exception,
    this.stackTrace,
  });

  final String message;
  final String? code;
  final Object? exception;
  final StackTrace? stackTrace;

  @override
  String toString() => 'Failure(message: $message, code: $code)';

  Failure copyWith({
    String? message,
    String? code,
    Object? exception,
    StackTrace? stackTrace,
  }) {
    return Failure(
      message: message ?? this.message,
      code: code ?? this.code,
      exception: exception ?? this.exception,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}
