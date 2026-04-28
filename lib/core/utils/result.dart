class Result<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;

  Result._({this.data, this.errorMessage, required this.isSuccess});

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(String message) =>
      Result._(errorMessage: message, isSuccess: false);
}

class Success<T> extends Result<T> {
  Success(T data) : super._(data: data, isSuccess: true);
}

class Failure<T> extends Result<T> {
  final Exception? exception;
  Failure(String message, {this.exception})
      : super._(errorMessage: message, isSuccess: false);
}
