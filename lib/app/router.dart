import 'package:go_router/go_router.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/tickets/presentation/my_tickets_screen.dart';
import '../features/tickets/presentation/create_ticket_screen.dart';
import '../features/tickets/presentation/ticket_detail_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/admin/presentation/admin_all_tickets_screen.dart';
import '../features/admin/presentation/admin_settings_screen.dart';
import '../features/admin/presentation/customers_directory_screen.dart';
import '../features/tickets/presentation/attachment_viewer_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/customer/tickets',
      builder: (context, state) => const MyTicketsScreen(),
    ),
    GoRoute(
      path: '/customer/tickets/create',
      builder: (context, state) => const CreateTicketScreen(),
    ),
    GoRoute(
      path: '/tickets/:id',
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        return TicketDetailScreen(ticketId: int.parse(idStr));
      },
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/tickets',
      builder: (context, state) => const AdminAllTicketsScreen(),
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminSettingsScreen(),
    ),
    GoRoute(
      path: '/admin/customers',
      builder: (context, state) => const CustomersDirectoryScreen(),
    ),
    GoRoute(
      path: '/attachments/viewer',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return AttachmentViewerScreen(
          fileName: extra['name'] as String? ?? 'Document',
          url: extra['url'] as String?,
          mimeType: extra['mimetype'] as String?,
          fileSize: extra['file_size'] as int?,
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
