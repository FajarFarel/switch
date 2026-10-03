
import 'package:go_router/go_router.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/events/event_list_page.dart';
import '../features/splash/splash_page.dart';
import '../features/switches/switch_detail_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String switchDetail = '/switch/:id';
  static const String switchEvents = '/switch/:id/events';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: switchDetail,
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '') ?? 0;
          return SwitchDetailPage(switchId: id);
        },
      ),
      GoRoute(
        path: switchEvents,
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final id = int.tryParse(idStr ?? '') ?? 0;
          return EventListPage(switchId: id);
        },
      ),
    ],
  );
}
