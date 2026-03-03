class UserFriendlyError {
  const UserFriendlyError._();

  static String message(
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
    String? action,
  }) {
    final raw = (error?.toString() ?? '').trim();
    final lower = raw.toLowerCase();

    if (lower.isEmpty) return fallback;

    final isNetwork =
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection') ||
        lower.contains('no address associated with hostname');
    if (isNetwork) {
      return 'Unable to connect right now. Please check your internet connection and try again.';
    }

    final isServer =
        lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('frappe request failed') ||
        lower.contains('internal server error');
    if (isServer) {
      return 'Our server is temporarily unavailable. Please try again in a moment.';
    }

    final isAuth =
        lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('not authenticated') ||
        lower.contains('invalid') ||
        lower.contains('incorrect') ||
        lower.contains('unauthorized');
    if (isAuth) {
      if (action == 'sign-in') {
        return 'Invalid email or password. Please try again.';
      }
      return 'Your session has expired. Please sign in again.';
    }

    if (lower.contains('client record not found')) {
      return 'We could not find your account details. Please contact support.';
    }

    if (lower.contains('not found')) {
      return 'The requested data was not found.';
    }

    if (lower.contains('validation') || lower.contains('invalid')) {
      return 'Some details are invalid. Please review and try again.';
    }

    return fallback;
  }
}
