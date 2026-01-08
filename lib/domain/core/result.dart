import '../failures/failure.dart';

abstract class Result<T> {
  const Result();

  bool get isSuccess => this is ResultSuccess<T>;
  bool get isFailure => this is ResultFailure<T>;

  Result<T> onSuccess(void Function(T data) action) {
    if (this is ResultSuccess<T>) {
      action((this as ResultSuccess<T>).data);
    }
    return this;
  }

  Result<T> onFailure(void Function(Failure failure) action) {
    if (this is ResultFailure<T>) {
      action((this as ResultFailure<T>).failure);
    }
    return this;
  }
}

class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.data);

  final T data;
}

class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;
}

class ResultUtils {
  ResultUtils._();

  static Result<T> guard<T>(T Function() run, {String? message}) {
    try {
      return ResultSuccess<T>(run());
    } catch (error, stackTrace) {
      return ResultFailure<T>(
        Failure(
          message: message ?? error.toString(),
          exception: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  static Future<Result<T>> guardFuture<T>(
    Future<T> Function() run, {
    String? message,
  }) async {
    try {
      final result = await run();
      return ResultSuccess<T>(result);
    } catch (error, stackTrace) {
      return ResultFailure<T>(
        Failure(
          message: message ?? error.toString(),
          exception: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
