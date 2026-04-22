// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/services.dart';
import 'package:glitch_garden/controllers/robot_buddy_controller.dart';
import 'package:glitch_garden/ui/painters/robot_painter1.dart';
import 'package:glitch_garden/ui/painters/robot_painters.dart';
import 'package:window_manager/window_manager.dart';

class RobotBuddy extends StatefulWidget {
  const RobotBuddy({super.key});

  @override
  State<RobotBuddy> createState() => _RobotBuddyState();
}

class _RobotBuddyState extends State<RobotBuddy> {
  Offset? _dragStartMouse;
  Offset? _dragStartWindow;
  bool showIntro = true;
  bool _drinkLocked = false;
  final FocusNode _focusNode = FocusNode(); // ← NEW for keyboard

  ShootDirection _shootDirection = ShootDirection.robotShootsMe;
  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus(); // ← NEW: Enable keyboard input

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => showIntro = false);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // ← NEW
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Only react on KeyDown
      if (event.logicalKey == LogicalKeyboardKey.space &&
          HardwareKeyboard.instance.isControlPressed) {
        final controller = RobotBuddyController.instance;

        // Prevent rapid triggering
        if (controller.isVoiceListening) {
          controller.stopVoiceListening();
        } else {
          controller.startVoiceListening(context);
        }
      }
    }
  }

  // ==================== DRINKS ====================
  final List<Map<String, String>> _drinks = [
    {"emoji": "🥤", "name": "Yummy!"},
    {"emoji": "🧃", "name": "Juicy!"},
    {"emoji": "☕", "name": "Coffee Time!"},
    {"emoji": "🍵", "name": "Zen Tea"},
    {"emoji": "🥛", "name": "Milk Shake"},
    {"emoji": "🧋", "name": "Bubble Bliss!"},
    {"emoji": "🍹", "name": "Tropical Vibes"},
    {"emoji": "🍸", "name": "Fancy Sip"},
    {"emoji": "🥃", "name": "Chill Drink"},
    {"emoji": "🍺", "name": "Cheers!"},
    {"emoji": "🧪", "name": "Robot Fuel"},
  ];

  Map<String, String> _currentDrink = {"emoji": "🥤", "name": "Yummy!"};

  // ==================== FOODS FOR EATING ====================
  final List<Map<String, String>> _foods = [
    {"emoji": "🍜", "name": "Slurppp!"},
    {"emoji": "🍝", "name": "Pasta Party"},
    {"emoji": "🍔", "name": "Burger Time!"},
    {"emoji": "🍕", "name": "Cheesy!"},
    {"emoji": "🍣", "name": "Sushi Roll"},
    {"emoji": "🍦", "name": "Sweet!"},
    {"emoji": "🍩", "name": "Donut Yum"},
    {"emoji": "🍪", "name": "Cookie!"},
    {"emoji": "🌮", "name": "Taco Time"},
    {"emoji": "🍟", "name": "Crunchy!"},
    {"emoji": "🍦", "name": "Ice Cream!"},
  ];

  Map<String, String> _currentFood = {"emoji": "🍜", "name": "Slurppp!"};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RobotBuddyController.instance,
      builder: (context, _) {
        final controller = RobotBuddyController.instance;
        final hour = DateTime.now().hour;
        final isNight = hour >= 19 || hour < 7;
        final isSunny = hour >= 12 && hour < 18;

        // Random drink when drinking starts
        // Random drink when drinking starts
        if (controller.mood == RobotMood.drinking &&
            _currentDrink["emoji"] == "🥤") {
          _currentDrink = _drinks[Random().nextInt(_drinks.length)];
        } else if (controller.mood != RobotMood.drinking) {
          _currentDrink = {"emoji": "🥤", "name": "Yummy!"};
        }

        // Random food when eating starts
        if (controller.mood == RobotMood.eating &&
            _currentFood["emoji"] == "🍜") {
          _currentFood = _foods[Random().nextInt(_foods.length)];
        } else if (controller.mood != RobotMood.eating) {
          _currentFood = {"emoji": "🍜", "name": "Slurppp!"};
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: KeyboardListener(
            // ← NEW WRAPPER
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: Stack(
              children: [
                DropTarget(
                  onDragDone: (_) {
                    controller.onDragDone(); // This sets mood to eating
                    // Reset food to random when new food is dropped
                    if (controller.mood == RobotMood.eating) {
                      _currentFood = _foods[Random().nextInt(_foods.length)];
                    }
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 130,
                      height: 180,
                      child: MouseRegion(
                        opaque: false,
                        onEnter: (_) => controller.onMouseEnter(),
                        onExit: (_) => controller.onMouseExit(),
                        child: Listener(
                          behavior: HitTestBehavior.deferToChild,
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent) {
                              controller.setScale(
                                controller.scale +
                                    event.scrollDelta.dy * -0.0007,
                              );
                              if (controller.mood != RobotMood.sick) {
                                controller.setMood(RobotMood.love);
                              }
                              controller.resetIdle();
                            }
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onSecondaryTapDown:
                                (details) => controller.showRadialContextMenu(
                                  context,
                                  details.globalPosition,
                                ),
                            onTap: controller.handleTap,

                            onPanStart: (details) async {
                              if (controller.isDown) return;
                              _dragStartMouse = details.globalPosition;
                              _dragStartWindow =
                                  await windowManager.getPosition();
                              controller.startDizzy();
                              if (controller.mood != RobotMood.sick) {
                                controller.setMood(RobotMood.dizzy);
                              }
                            },

                            onPanUpdate: (details) async {
                              if (_dragStartMouse == null ||
                                  _dragStartWindow == null) {
                                return;
                              }
                              final delta =
                                  details.globalPosition - _dragStartMouse!;
                              await windowManager.setPosition(
                                Offset(
                                  _dragStartWindow!.dx + delta.dx,
                                  _dragStartWindow!.dy + delta.dy,
                                ),
                              );
                            },

                            onPanEnd: (_) {
                              _dragStartMouse = null;
                              _dragStartWindow = null;
                              controller.wakeUpByDragEnd();
                            },

                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedBuilder(
                                  animation: Listenable.merge([
                                    controller.glow,
                                    controller.dizzySpin,
                                    controller.chompController,
                                    controller.jumpController,
                                    controller.confettiController,
                                    controller.antennaController,
                                    controller.chargeController,
                                    controller.snoreController,
                                    controller.sleepShakeController,
                                    controller.fallController,
                                    controller.handController,
                                    controller.idleScaleController,
                                    controller.walkController,
                                    controller.drinkController,
                                    controller.dotsController,
                                    controller.sunglassesController,
                                    controller.stretchController,
                                    controller.phoneTapController,
                                    controller.headTiltController,
                                    controller.eyeMoveController,
                                    controller
                                        .danceController, // ← Make sure this is here
                                  ]),
                                  builder: (context, _) {
                                    final tiredFactor =
                                        controller.mood == RobotMood.sick
                                            ? 0.4
                                            : controller.mood == RobotMood.sleep
                                            ? 0.0
                                            : 1.0;
                                    final jumpY =
                                        controller.mood == RobotMood.excited
                                            ? -controller.jumpController.value *
                                                30.0 *
                                                tiredFactor
                                            : 0.0;
                                    final t =
                                        controller.walkController.value *
                                        2 *
                                        pi;

                                    final walkX =
                                        controller.isWalking ? sin(t) * 6 : 0.0;
                                    final walkY =
                                        controller.isWalking
                                            ? (sin(t).abs()) * -4
                                            : 0.0;

                                    return Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Charging lightning
                                        if (controller.batteryState ==
                                            BatteryState.charging)
                                          Positioned(
                                            top: -38,
                                            child: AnimatedBuilder(
                                              animation:
                                                  controller.chargeController,
                                              builder: (_, __) {
                                                final offsetY =
                                                    sin(
                                                      2 *
                                                          pi *
                                                          controller
                                                              .chargeController
                                                              .value,
                                                    ) *
                                                    5;
                                                return Transform.translate(
                                                  offset: Offset(0, offsetY),
                                                  child: const Text(
                                                    "⚡",
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      color:
                                                          Colors.yellowAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.yellow,
                                                          blurRadius: 6,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                        // Snore Zzz
                                        if (controller.mood == RobotMood.sleep)
                                          Positioned(
                                            top: -32,
                                            right: -15,
                                            child: IgnorePointer(
                                              child: AnimatedBuilder(
                                                animation:
                                                    controller.snoreController,
                                                builder: (_, __) {
                                                  final idx =
                                                      (controller
                                                                  .snoreController
                                                                  .value *
                                                              controller
                                                                  .snores
                                                                  .length)
                                                          .floor();
                                                  return Opacity(
                                                    opacity:
                                                        0.4 +
                                                        (0.6 *
                                                            (1 -
                                                                controller
                                                                    .snoreController
                                                                    .value)),
                                                    child: Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        controller
                                                            .snoreFloat
                                                            .value,
                                                      ),
                                                      child: Text(
                                                        controller.snores[idx %
                                                            controller
                                                                .snores
                                                                .length],
                                                        style: TextStyle(
                                                          fontSize:
                                                              15 +
                                                              (controller
                                                                      .snoreController
                                                                      .value *
                                                                  6),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: controller
                                                              .getMoodColor()
                                                              .withOpacity(
                                                                0.75,
                                                              ),
                                                          shadows: [
                                                            Shadow(
                                                              blurRadius: 8,
                                                              color: Colors
                                                                  .cyanAccent
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),

                                        // Confetti
                                        if (controller.mood ==
                                            RobotMood.excited)
                                          ...controller.buildConfetti(),

                                        // Main Robot
                                        // Main Robot
                                        // Main Robot
                                        AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 1200,
                                          ),
                                          opacity:
                                              (controller.mood ==
                                                          RobotMood.sleep ||
                                                      controller.isDown)
                                                  ? 0.45
                                                  : 1.0,
                                          child: Transform.translate(
                                            offset:
                                                controller.isDancing
                                                    ? Offset(
                                                      controller.danceX,
                                                      -controller.danceY,
                                                    )
                                                    : Offset(
                                                      walkX +
                                                          controller
                                                              .sleepShake
                                                              .value,
                                                      jumpY + walkY,
                                                    ),
                                            child: Transform.rotate(
                                              angle:
                                                  controller.isDancing
                                                      ? controller.danceTilt
                                                      : (controller.isWalking
                                                          ? sin(t) * 0.05
                                                          : 0),
                                              child: Transform.scale(
                                                scale:
                                                    controller.isDancing
                                                        ? controller.danceScale
                                                        : controller.scale *
                                                                controller
                                                                    .idleScaleAnimation
                                                                    .value +
                                                            (controller.mood ==
                                                                    RobotMood
                                                                        .excited
                                                                ? controller
                                                                        .glow
                                                                        .value *
                                                                    0.05
                                                                : 0),

                                                child: RepaintBoundary(
                                                  child: CustomPaint(
                                                    size:
                                                        controller.useEvoStyle
                                                            ? const Size(
                                                              130,
                                                              170,
                                                            )
                                                            : const Size(
                                                              110,
                                                              150,
                                                            ),
                                                    painter:
                                                        controller.useEvoStyle
                                                            ? RobotPainter1(
                                                              mood:
                                                                  controller
                                                                      .mood,
                                                              blink:
                                                                  controller
                                                                      .blink,
                                                              faceColor:
                                                                  controller
                                                                      .getMoodColor(),
                                                              dizzyAngle:
                                                                  controller
                                                                      .dizzySpin
                                                                      .value,
                                                              chompVal:
                                                                  controller
                                                                      .chompController
                                                                      .value,
                                                              antennaVal:
                                                                  controller
                                                                      .antennaController
                                                                      .value,
                                                              isNight: isNight,
                                                              isSunny: isSunny,
                                                              showHat:
                                                                  controller
                                                                      .showHat,
                                                              showGlasses:
                                                                  controller
                                                                      .showGlasses,
                                                              shootOffset:
                                                                  controller
                                                                      .shootOffset,
                                                              fallOffset:
                                                                  controller
                                                                      .fallAnimation
                                                                      .value,
                                                              eyeOffset:
                                                                  controller
                                                                      .eyeOffset,
                                                              drinkProgress:
                                                                  controller
                                                                      .drinkController
                                                                      .value,
                                                              phoneTapProgress:
                                                                  controller
                                                                      .phoneTapController
                                                                      .value,
                                                              drinkEmoji:
                                                                  _currentDrink["emoji"]!,
                                                              crabX:
                                                                  controller
                                                                      .crabX,
                                                              crabY:
                                                                  controller
                                                                      .crabY,
                                                              crabTilt:
                                                                  controller
                                                                      .crabTilt,
                                                              danceCycle:
                                                                  controller
                                                                      .danceValue
                                                                      .value,
                                                              isDancing:
                                                                  controller
                                                                      .isDancing,
                                                              // NEW PROGRESS VALUES
                                                              singingProgress:
                                                                  controller
                                                                      .singingProgress,
                                                              smokingProgress:
                                                                  controller
                                                                      .smokingProgress,
                                                              ghostProgress:
                                                                  controller
                                                                      .ghostProgress,
                                                              showLoveEyes:
                                                                  controller
                                                                      .showLoveEyes, // ← ADD THIS
                                                            )
                                                            : RobotPainter(
                                                              mood:
                                                                  controller
                                                                      .mood,
                                                              blink:
                                                                  controller
                                                                      .blink,
                                                              faceColor:
                                                                  controller
                                                                      .getMoodColor(),
                                                              dizzyAngle:
                                                                  controller
                                                                      .dizzySpin
                                                                      .value,
                                                              chompVal:
                                                                  controller
                                                                      .chompController
                                                                      .value,
                                                              antennaVal:
                                                                  controller
                                                                      .antennaController
                                                                      .value,
                                                              isNight: isNight,
                                                              isSunny: isSunny,
                                                              shootOffset:
                                                                  controller
                                                                      .handAnimation
                                                                      .value,
                                                              fallOffset:
                                                                  controller
                                                                      .fallAnimation
                                                                      .value,
                                                              eyeOffset:
                                                                  controller
                                                                      .eyeOffset,
                                                              drinkProgress:
                                                                  controller
                                                                      .drinkController
                                                                      .value,
                                                              phoneTapProgress:
                                                                  controller
                                                                      .phoneTapController
                                                                      .value,
                                                              drinkEmoji:
                                                                  _currentDrink["emoji"]!,
                                                              danceCycle:
                                                                  controller
                                                                      .danceValue
                                                                      .value,
                                                              isDancing:
                                                                  controller
                                                                      .isDancing,
                                                              // NEW PROGRESS VALUES
                                                              singingProgress:
                                                                  controller
                                                                      .singingProgress,
                                                              smokingProgress:
                                                                  controller
                                                                      .smokingProgress,
                                                              ghostProgress:
                                                                  controller
                                                                      .ghostProgress,
                                                            ),
                                                    willChange:
                                                        controller.isDancing,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Digital Clock
                                        if (controller.mood ==
                                                RobotMood.sleep &&
                                            controller.showClock)
                                          Positioned(
                                            top: 22,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.4,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.cyanAccent
                                                      .withOpacity(0.5),
                                                  width: 1,
                                                ),
                                              ),
                                              child: StreamBuilder<DateTime>(
                                                stream: Stream.periodic(
                                                  const Duration(
                                                    milliseconds: 500,
                                                  ),
                                                  (_) => DateTime.now(),
                                                ),
                                                builder: (context, snapshot) {
                                                  final now =
                                                      snapshot.data ??
                                                      DateTime.now();
                                                  final hour12 =
                                                      now.hour % 12 == 0
                                                          ? 12
                                                          : now.hour % 12;
                                                  final minuteStr = now.minute
                                                      .toString()
                                                      .padLeft(2, '0');
                                                  final amPm =
                                                      now.hour >= 12
                                                          ? 'PM'
                                                          : 'AM';
                                                  final showColon =
                                                      (now.millisecond ~/ 500) %
                                                          2 ==
                                                      0;
                                                  return Text(
                                                    "$hour12${showColon ? ':' : ' '}$minuteStr $amPm",
                                                    style: const TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.cyanAccent,
                                                      letterSpacing: 2,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),

                                        // Speech Bubble
                                        if (controller.showSpeech)
                                          Positioned(
                                            top: -92,
                                            left: 0,
                                            right: 0,
                                            child: Center(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 9,
                                                    ),
                                                constraints:
                                                    const BoxConstraints(
                                                      maxWidth: 250,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  border: Border.all(
                                                    color:
                                                        controller
                                                            .getMoodColor(),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Text(
                                                  controller.currentSpeech,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                        // Thinking dots
                                        if (controller.showDots)
                                          Positioned(
                                            top: -62,
                                            child: AnimatedBuilder(
                                              animation:
                                                  controller.dotsController,
                                              builder: (_, __) {
                                                final count =
                                                    (controller
                                                                .dotsController
                                                                .value *
                                                            3)
                                                        .floor() +
                                                    1;
                                                return Row(
                                                  children: List.generate(
                                                    count,
                                                    (i) => const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 1.5,
                                                          ),
                                                      child: Text(
                                                        ".",
                                                        style: TextStyle(
                                                          fontSize: 24,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                        // ==================== DRINK ANIMATION (Smooth) ====================
                                        if (controller.isDrinking)
                                          Positioned(
                                            right: -55, // move more right
                                            top: 20, // slightly higher
                                            child: AnimatedBuilder(
                                              animation:
                                                  controller.drinkController,
                                              builder: (_, __) {
                                                final tilt =
                                                    sin(
                                                      controller
                                                              .drinkController
                                                              .value *
                                                          4 *
                                                          pi,
                                                    ) *
                                                    0.18; // more noticeablelt
                                                return Transform.rotate(
                                                  angle: tilt,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        _currentDrink["emoji"]!,
                                                        style: const TextStyle(
                                                          fontSize: 34,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _currentDrink["name"]!,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white
                                                              .withOpacity(0.9),
                                                          shadows: [
                                                            Shadow(
                                                              color:
                                                                  Colors
                                                                      .black54,
                                                              blurRadius: 3,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                        // ==================== EATING ANIMATION (Smooth) ====================
                                        if (controller.mood == RobotMood.eating)
                                          Positioned(
                                            left: -60, // push further left
                                            top: 22, // slightly higher
                                            child: AnimatedBuilder(
                                              animation:
                                                  controller.chompController,
                                              builder: (_, __) {
                                                // Much smoother chomp effect
                                                final chompScale =
                                                    0.96 +
                                                    sin(
                                                          controller
                                                                  .chompController
                                                                  .value *
                                                              pi *
                                                              1.5, // much slower chewing
                                                        ) *
                                                        0.08; // softer movement
                                                return Transform.scale(
                                                  scale: chompScale,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        _currentFood["emoji"]!,
                                                        style: const TextStyle(
                                                          fontSize: 38,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 6,
                                                      ), // 👈 more space
                                                      Text(
                                                        _currentFood["name"]!,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors
                                                                  .orangeAccent,
                                                          shadows: [
                                                            Shadow(
                                                              color:
                                                                  Colors.black,
                                                              blurRadius: 6,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                        // Pizza extra visual
                                        if (controller.isPizza)
                                          const Positioned(
                                            left: -32,
                                            top: 25,
                                            child: Text(
                                              "🍕",
                                              style: TextStyle(fontSize: 26),
                                            ),
                                          ),

                                        // Cool sunglasses
                                        if (controller.isCool)
                                          Positioned(
                                            top:
                                                -12 +
                                                (controller
                                                        .sunglassesController
                                                        .value *
                                                    -25),
                                            child: Text(
                                              'Yo Wazzup!',
                                              style: TextStyle(
                                                color: Colors.pink,
                                              ),
                                            ),
                                          ),

                                        // Lazy stretch
                                        if (controller.isLazy)
                                          Positioned(
                                            bottom: -18,
                                            child: AnimatedBuilder(
                                              animation:
                                                  controller.stretchController,
                                              builder: (_, __) {
                                                return Transform.scale(
                                                  scaleY:
                                                      1 +
                                                      (controller
                                                              .stretchController
                                                              .value *
                                                          0.25),
                                                  child: const Text(
                                                    "🦥",
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                        // Distracted phone
                                        if (controller.isDistracted)
                                          Positioned(
                                            right: -38,
                                            child: AnimatedBuilder(
                                              animation:
                                                  controller.phoneTapController,
                                              builder: (_, __) {
                                                final offset =
                                                    sin(
                                                      controller
                                                              .phoneTapController
                                                              .value *
                                                          pi,
                                                    ) *
                                                    6;
                                                return Transform.translate(
                                                  offset: Offset(0, offset),
                                                  child: const Text(
                                                    "📱",
                                                    style: TextStyle(
                                                      fontSize: 26,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                        // Curious
                                        if (controller.isCurious)
                                          Positioned(
                                            top: -55,
                                            child: AnimatedBuilder(
                                              animation:
                                                  controller.headTiltController,
                                              builder: (_, __) {
                                                final angle =
                                                    sin(
                                                      controller
                                                              .headTiltController
                                                              .value *
                                                          pi,
                                                    ) *
                                                    0.45;
                                                return Transform.rotate(
                                                  angle: angle,
                                                  child: const Text(
                                                    "❓",
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // ==================== LISTENING OVERLAY ====================
                if (controller.isVoiceListening)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.75),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic, size: 85, color: Colors.redAccent),
                            SizedBox(height: 20),
                            Text(
                              "Listening...",
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Speak now!\nPress Ctrl + Space to cancel",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (controller.showCapturedImage &&
                    controller.lastCapturedImage != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: controller.showCapturedImage ? 1 : 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.75),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                File(controller.lastCapturedImage!),
                                width: 320,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
