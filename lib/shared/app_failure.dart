enum AppFailureKind {
  timeout,
  transport,
  authentication,
  rateLimited,
  serviceUnavailable,
  invalidResponse,
  missingConfiguration,
  storage,
  noData,
  refreshLimited,
}

class AppFailure implements Exception {
  const AppFailure(this.kind, {this.statusCode, this.retryAfter});

  final AppFailureKind kind;
  final int? statusCode;
  final Duration? retryAfter;
}
