import 'package:flutter/material.dart';
import '../errors/failures.dart';
import '../theme/app_theme.dart';

class AppDialogs {
  /// Presents an immediate pop-up modal dialog for errors and validation notices.
  /// Eliminates developer lingo and avoids forcing the user to scroll down a page.
  static Future<void> showErrorDialog(
    BuildContext context, {
    String title = 'Notice',
    required dynamic error,
  }) {
    String displayMessage;

    if (error is Failure) {
      displayMessage = error.userFriendlyMessage;
    } else if (error is Exception) {
      final str = error.toString().replaceFirst('Exception: ', '');
      if (str.contains('SocketException') || str.contains('Network') || str.contains('DioException')) {
        displayMessage = 'Unable to reach the Helpdesk server. Please check your internet connection.';
      } else {
        displayMessage = str;
      }
    } else if (error is String) {
      displayMessage = error;
    } else if (error is Error) {
      displayMessage = 'An unexpected issue occurred: ${error.toString().split('\n').first}';
    } else {
      displayMessage = error?.toString() ?? 'An unexpected issue occurred. Please try again.';
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppTheme.surfaceCard,
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8D7DA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB02A37),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            displayMessage,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Displays an immediate, pleasant confirmation toast with a checkmark icon.
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF0F5132),
        elevation: 4,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
