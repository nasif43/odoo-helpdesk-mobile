class Failure {
  final String message;
  final String? code;
  final Map<String, dynamic>? fields;

  const Failure(this.message, {this.code, this.fields});

  /// Translates technical error codes and developer semantics into layman-friendly messages.
  String get userFriendlyMessage {
    final c = code?.toUpperCase();
    if (c == 'INVALID_CREDENTIALS') {
      return 'The email or password entered is incorrect. Please check your credentials and try again.';
    } else if (c == 'UNAUTHORIZED' || c == 'SESSION_EXPIRED') {
      return 'Your session has expired. Please sign in again.';
    } else if (c == 'ACCESS_DENIED' || c == 'FORBIDDEN') {
      return 'You do not have permission to perform this action.';
    } else if (c == 'NOT_FOUND' || c == 'TICKET_NOT_FOUND') {
      return 'The requested ticket or item could not be found.';
    } else if (c == 'VALIDATION_ERROR') {
      if (fields != null && fields!.isNotEmpty) {
        final fieldNames = fields!.keys.map((k) => k.replaceAll('x_', '').replaceAll('_', ' ')).join(', ');
        return 'Please review the required details: $fieldNames.';
      }
      return 'Please check the information entered and ensure all required fields are complete.';
    } else if (c == 'CONNECTION_ERROR' || c == 'NETWORK_ERROR') {
      return 'Unable to reach the Helpdesk server. Please check your internet connection.';
    }

    // Clean up technical artifacts from the message if present
    var clean = message.trim();
    if (clean.contains('DioException') || clean.contains('SocketException') || clean.contains('Failed host lookup')) {
      return 'Unable to connect to the Helpdesk server. Please check your internet connection.';
    }
    if (clean.contains('HTTP') || clean.contains('status code')) {
      return 'The server encountered an issue while processing your request. Please try again.';
    }
    return clean.isNotEmpty ? clean : 'An unexpected error occurred. Please try again.';
  }

  @override
  String toString() => userFriendlyMessage;
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});

  @override
  String get userFriendlyMessage => 'Unable to connect to the Helpdesk server. Please check your connection.';
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.fields, super.code});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});

  @override
  String get userFriendlyMessage => 'The Helpdesk service encountered a temporary error. Please try again in a moment.';
}
