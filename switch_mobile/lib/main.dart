import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'features/auth/auth_controller.dart';
import 'features/events/event_controller.dart';
import 'features/switches/switch_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => SwitchController()),
        ChangeNotifierProvider(create: (_) => EventController()),
      ],
      child: const MyApp(),
    ),
  );
}
