import 'package:flutter/material.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/admin/screens/admin_dashboard.dart';

class AppRouter {
  static const String initial = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> get routes => {
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    admin: (context) => const AdminDashboard(),
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
