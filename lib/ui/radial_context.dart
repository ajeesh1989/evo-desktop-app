import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glitch_garden/controllers/robot_buddy_controller.dart';

class RadialContextMenu extends StatefulWidget {
  final Offset center;
  final Function(RobotCommand, BuildContext) onCommand;
  final VoidCallback onDismiss;
  final RobotBuddyController controller;

  const RadialContextMenu({
    super.key,
    required this.center,
    required this.onCommand,
    required this.onDismiss,
    required this.controller,
  });

  @override
  State<RadialContextMenu> createState() => _RadialContextMenuState();
}

class _RadialContextMenuState extends State<RadialContextMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double safe(double v) {
    if (!v.isFinite) return 0.0;
    return v.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(RobotCommand cmd) {
    widget.onCommand(cmd, context);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) widget.onDismiss();
    });
  }

  void _toggleMute() {
    widget.controller.toggleMute();
    // Rebuild to update mute icon and label immediately
    if (mounted) setState(() {});
  }

  // Voice command via mic
  void _startVoiceCommand() {
    widget.controller.startVoiceListening(context);
    widget.onDismiss();
  }

  // Menu Items
  // Updated menu items
  // Menu Items
  List<_MenuItem> get _items => [
    // Top Row - Most Used
    _MenuItem(
      command: RobotCommand.dance,
      icon: FontAwesomeIcons.music,
      label: "Dance",
      color: Colors.pinkAccent,
    ),
    _MenuItem(
      command: RobotCommand.sing, // ← NEW
      icon: FontAwesomeIcons.microphone,
      label: "Sing",
      color: Colors.deepPurpleAccent,
    ),
    _MenuItem(
      command: RobotCommand.joke,
      icon: FontAwesomeIcons.faceSmile,
      label: "Joke",
      color: Colors.purpleAccent,
    ),
    _MenuItem(
      command: RobotCommand.camera,
      icon: FontAwesomeIcons.camera,
      label: "Cam",
      color: Colors.tealAccent,
    ),

    // Fun Actions
    _MenuItem(
      command: RobotCommand.pizza,
      icon: FontAwesomeIcons.pizzaSlice,
      label: "Pizza",
      color: Colors.redAccent,
    ),
    _MenuItem(
      command: RobotCommand.drink,
      icon: FontAwesomeIcons.mugHot,
      label: "Drink",
      color: Colors.blue,
    ),
    _MenuItem(
      command: RobotCommand.walk,
      icon: FontAwesomeIcons.personWalking,
      label: "Walk",
      color: Colors.green,
    ),

    // New Special Modes
    _MenuItem(
      command: RobotCommand.smoke, // ← NEW
      icon: FontAwesomeIcons.smoking,
      label: "Smoke",
      color: Colors.grey,
    ),
    _MenuItem(
      command: RobotCommand.ghost, // ← NEW
      icon: FontAwesomeIcons.ghost,
      label: "Ghost",
      color: Colors.cyanAccent,
    ),

    // Mood / Actions
    _MenuItem(
      command: RobotCommand.reading,
      icon: FontAwesomeIcons.bookOpen,
      label: "Read",
      color: Colors.brown,
    ),
    _MenuItem(
      command: RobotCommand.catching,
      icon: FontAwesomeIcons.fly,
      label: "Catch",
      color: Colors.lightGreen,
    ),

    // Cool & Distracted
    _MenuItem(
      command: RobotCommand.cool,
      icon: FontAwesomeIcons.glasses,
      label: "Rizz",
      color: Colors.amber,
    ),
    _MenuItem(
      command: RobotCommand.distracted,
      icon: FontAwesomeIcons.mobileScreen,
      label: "Phone",
      color: Colors.deepOrange,
    ),

    // Bottom Row
    _MenuItem(
      command: RobotCommand.sleep,
      icon: FontAwesomeIcons.bedPulse,
      label: "Sleep",
      color: Colors.blueGrey,
    ),
    _MenuItem(
      command: RobotCommand.shoot,
      icon: FontAwesomeIcons.gun,
      label: "Shoot",
      color: Colors.red,
    ),
    _MenuItem(
      command: RobotCommand.toggleStyle,
      icon:
          widget.controller.useEvoStyle
              ? FontAwesomeIcons.robot
              : FontAwesomeIcons.android,
      label: widget.controller.useEvoStyle ? "Classic" : "EVO",
      color: Colors.cyanAccent,
    ),

    // Mute Button
    _MenuItem(
      command: RobotCommand.cool, // dummy
      icon:
          widget.controller.isMuted
              ? FontAwesomeIcons.volumeXmark
              : FontAwesomeIcons.volumeHigh,
      label: widget.controller.isMuted ? "Unmute" : "Mute",
      color: Colors.deepPurpleAccent,
      isMute: true,
    ),

    // Exit
    _MenuItem(
      command: RobotCommand.exit,
      icon: FontAwesomeIcons.xmark,
      label: "Exit",
      color: Colors.redAccent,
      isDestructive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const double radius = 135;
    const double size = 55;

    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none, // ⭐ IMPORTANT FIX
        children: [
          // Background dismiss
          GestureDetector(
            onTap: widget.onDismiss,
            child: Container(color: Colors.transparent),
          ),

          // Menu Items
          ...List.generate(_items.length, (i) {
            final item = _items[i];
            final angle = (i / _items.length) * 2 * math.pi - math.pi / 2;

            return AnimatedBuilder(
              animation: _animation,
              builder: (_, __) {
                final t = safe(_animation.value);
                final dx = math.cos(angle) * radius * t;
                final dy = math.sin(angle) * radius * t;

                return Positioned(
                  left: widget.center.dx - size / 2,
                  top: widget.center.dy - size / 2,
                  child: Transform.translate(
                    offset: Offset(dx, dy),
                    child: Opacity(
                      opacity: t,
                      child: GestureDetector(
                        onTap: () {
                          if (item.isMute == true) {
                            _toggleMute();
                          } else if (item.isVoice == true) {
                            _startVoiceCommand();
                          } else {
                            _select(item.command);
                          }
                        },
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 22, 22, 23),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.color.withOpacity(0.85),
                              width: 2.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(item.icon, color: item.color, size: 18),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Center Glow
          Positioned(
            left: widget.center.dx - 28,
            top: widget.center.dy - 28,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) {
                final t = safe(_animation.value);
                return Opacity(
                  opacity: (1 - t) * 0.4,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final RobotCommand command;
  final FaIconData icon;
  final String label;
  final Color color;
  final bool isDestructive;
  final bool isVoice;
  final bool isMute;

  _MenuItem({
    required this.command,
    required this.icon,
    required this.label,
    required this.color,
    this.isDestructive = false,
    this.isVoice = false,
    this.isMute = false,
  });
}
