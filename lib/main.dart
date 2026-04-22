// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:glitch_garden/controllers/robot_buddy_controller.dart';
import 'package:glitch_garden/ui/robot_buddy.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(350, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();

    await windowManager.setHasShadow(false); // 🔥 FIXES BOX
    await windowManager.setBackgroundColor(Colors.transparent);

    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const RobotApp());
}

class RobotApp extends StatelessWidget {
  const RobotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent, // 🔥 helps avoid artifacts
      home: RobotScreen(),
    );
  }
}

// Wrapper for TickerProvider
class RobotScreen extends StatefulWidget {
  const RobotScreen({super.key});

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    RobotBuddyController.instance.initialize(this);
  }

  @override
  void dispose() {
    RobotBuddyController.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const RobotBuddy();
  }
}
