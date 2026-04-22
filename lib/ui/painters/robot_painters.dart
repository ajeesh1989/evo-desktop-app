import 'dart:math';
import 'package:flutter/material.dart';
import 'package:glitch_garden/controllers/robot_buddy_controller.dart';

class RobotPainter extends CustomPainter {
  final RobotMood mood;
  final bool blink, isNight, isSunny;
  final Color faceColor;
  final double dizzyAngle, chompVal, antennaVal;
  final double shootOffset;
  final double fallOffset;
  final Offset eyeOffset;
  final String drinkEmoji;
  final double drinkProgress;
  final double phoneTapProgress;
  final double danceCycle;
  final bool isDancing;
  final double singingProgress; // ← NEW
  final double smokingProgress; // ← NEW
  final double ghostProgress; // ← NEW

  RobotPainter({
    required this.mood,
    required this.blink,
    required this.faceColor,
    required this.dizzyAngle,
    required this.chompVal,
    required this.antennaVal,
    required this.isNight,
    required this.isSunny,
    this.shootOffset = 0,
    this.fallOffset = 0,
    this.eyeOffset = Offset.zero,
    this.drinkProgress = 0.0,
    this.phoneTapProgress = 0.0,
    this.drinkEmoji = "🥤",
    this.danceCycle = 0.0,
    this.isDancing = false,
    this.singingProgress = 0.0,
    this.smokingProgress = 0.0,
    this.ghostProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    canvas.save();

    // ====================== GHOST MODE SETUP ======================
    double ghostOpacity = 1.0;
    double ghostFloatY = 0.0;

    if (mood == RobotMood.ghost) {
      final t = ghostProgress * 2 * pi;
      ghostOpacity = 0.7 + sin(t) * 0.2;
      ghostFloatY = sin(t * 0.8) * 6;
      canvas.translate(0, ghostFloatY);
    }

    // ====================== DANCING + DIZZY + FALL TRANSFORMS ======================
    double moveX = 0;
    double moveY = 0;
    double tilt = fallOffset;

    if (isDancing) {
      moveX = sin(danceCycle * 2 * pi) * 14;
      moveY = cos(danceCycle * 5 * pi) * 10;
      tilt = sin(danceCycle * 4 * pi) * 0.25;
    } else if (mood == RobotMood.dizzy) {
      moveX = sin(dizzyAngle * 20) * 4;
      moveY = cos(dizzyAngle * 18) * 2;
      tilt = sin(dizzyAngle * 2 * pi) * 0.28;
    }

    canvas.translate(center.dx + moveX, center.dy + moveY);
    canvas.rotate(tilt);
    canvas.translate(-center.dx, -center.dy);

    if (isDancing) {
      canvas.translate(0, sin(danceCycle * 6.5 * pi) * 3);
    }

    // ====================== HEAD TRANSFORM ======================
    if (mood == RobotMood.dizzy) {
      final shakeX = sin(dizzyAngle * 20) * 3;
      final shakeY = cos(dizzyAngle * 18) * 2;
      canvas.translate(center.dx + shakeX, center.dy + shakeY);
      canvas.rotate(sin(dizzyAngle * 2 * pi) * 0.25);
      canvas.translate(-center.dx, -center.dy);
    } else {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(fallOffset);
      canvas.translate(-center.dx, -center.dy);
    }

    final dark =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2.8
          ..style = PaintingStyle.stroke;

    final fillDark = Paint()..color = Colors.black;

    // ====================== ANTENNA ======================
    final antennaPaint =
        Paint()
          ..color = Colors.grey[700]!.withOpacity(ghostOpacity)
          ..strokeWidth = 3;

    final double antennaJiggle =
        (mood == RobotMood.dizzy) ? sin(dizzyAngle * 12) * 12 : antennaVal * 5;

    canvas.drawLine(
      center + const Offset(0, -40),
      center + Offset(antennaJiggle, -60),
      antennaPaint,
    );
    canvas.drawCircle(
      center + Offset(antennaJiggle, -63),
      4,
      Paint()..color = faceColor.withOpacity(ghostOpacity),
    );

    // ====================== HEAD ======================
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 100, height: 80),
        const Radius.circular(18),
      ),
      Paint()..color = faceColor.withOpacity(ghostOpacity),
    );
    // ====================== CHEEKS ======================
    if (mood == RobotMood.love || mood == RobotMood.excited) {
      final blushOpacity = mood == RobotMood.ghost ? ghostOpacity * 0.6 : 0.3;
      final blush = Paint()..color = Colors.white.withOpacity(blushOpacity);

      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(-35, 10),
          width: 15,
          height: 8,
        ),
        blush,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(35, 10),
          width: 15,
          height: 8,
        ),
        blush,
      );
    }

    // ====================== NIGHT CAP ======================
    if (isNight && mood != RobotMood.dizzy) {
      final capPaint =
          Paint()..color = Colors.red[800]!.withOpacity(ghostOpacity);
      final capPath =
          Path()
            ..moveTo(center.dx - 30, center.dy - 38)
            ..quadraticBezierTo(
              center.dx,
              center.dy - 70,
              center.dx + 40,
              center.dy - 35,
            )
            ..close();
      canvas.drawPath(capPath, capPaint);

      canvas.drawCircle(
        center + const Offset(45, -35),
        6,
        Paint()..color = Colors.white.withOpacity(ghostOpacity),
      );
    }

    // ====================== EYES ======================
    Offset leftEye = center + const Offset(-18, -5) + eyeOffset;
    Offset rightEye = center + const Offset(18, -5) + eyeOffset;

    if (mood == RobotMood.dizzy) {
      leftEye += Offset(sin(dizzyAngle * 13) * 6, cos(dizzyAngle * 11) * 6);
      rightEye += Offset(cos(dizzyAngle * 17) * 6, sin(dizzyAngle * 19) * 6);
    }

    void normalEye(Offset pos) {
      canvas.drawCircle(
        pos,
        5.5,
        Paint()..color = Colors.black.withOpacity(ghostOpacity),
      );
      if (![
        RobotMood.lazy,
        RobotMood.drowsy,
        RobotMood.sleep,
        RobotMood.dizzy,
        RobotMood.distracted,
      ].contains(mood)) {
        canvas.drawCircle(
          pos,
          2.8,
          Paint()..color = Colors.white.withOpacity(ghostOpacity),
        );
      }
    }

    // Ghost Eyes
    // Ghost Eyes
    if (mood == RobotMood.ghost) {
      final ghostEyeOffset = Offset(
        sin(ghostProgress * 12) * 1.2,
        cos(ghostProgress * 8) * 0.8,
      );
      final eyePaint =
          Paint()..color = Colors.black.withOpacity(ghostOpacity * 0.9);

      canvas.drawCircle(leftEye + ghostEyeOffset, 5.8, eyePaint);
      canvas.drawCircle(rightEye + ghostEyeOffset, 5.8, eyePaint);

      final glowPaint =
          Paint()
            ..color = Colors.cyanAccent.withOpacity(0.25 * ghostOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5;
      canvas.drawCircle(leftEye + ghostEyeOffset, 9, glowPaint);
      canvas.drawCircle(rightEye + ghostEyeOffset, 9, glowPaint);
    } else if (mood == RobotMood.cool || isSunny) {
      final glass = Paint()..color = Colors.black;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: leftEye, width: 35, height: 20),
          const Radius.circular(4),
        ),
        glass,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: rightEye, width: 35, height: 20),
          const Radius.circular(4),
        ),
        glass,
      );
      canvas.drawLine(
        center + const Offset(-5, -5),
        center + const Offset(5, -5),
        dark..strokeWidth = 3,
      );
    } else if (mood == RobotMood.lazy || mood == RobotMood.drowsy) {
      canvas.drawLine(
        leftEye + const Offset(-7, 3),
        leftEye + const Offset(7, 6),
        dark,
      );
      canvas.drawLine(
        rightEye + const Offset(-7, 3),
        rightEye + const Offset(7, 6),
        dark,
      );
    } else if (mood == RobotMood.thinking) {
      canvas.drawCircle(leftEye, 3.5, fillDark);
      normalEye(rightEye);
      canvas.drawCircle(
        center + const Offset(32, -32),
        7,
        Paint()..color = Colors.white.withOpacity(0.85),
      );
      canvas.drawCircle(
        center + const Offset(42, -42),
        3.5,
        Paint()..color = Colors.white.withOpacity(0.6),
      );
    } else if (mood == RobotMood.curious) {
      canvas.drawCircle(leftEye + const Offset(1, -4), 5.5, fillDark);
      canvas.drawCircle(rightEye + const Offset(-1, 3), 5.5, fillDark);
      canvas.drawLine(
        leftEye + const Offset(-9, -10),
        leftEye + const Offset(7, -7),
        dark,
      );
    } else if (mood == RobotMood.distracted) {
      canvas.drawCircle(leftEye + const Offset(0, 7.5), 5.5, fillDark);
      canvas.drawCircle(rightEye + const Offset(0, 7.5), 5.5, fillDark);
    } else if (mood == RobotMood.sleep || blink) {
      final path =
          Path()
            ..addArc(
              Rect.fromCenter(center: leftEye, width: 16, height: 10),
              pi,
              pi,
            )
            ..addArc(
              Rect.fromCenter(center: rightEye, width: 16, height: 10),
              pi,
              pi,
            );
      canvas.drawPath(path, dark);
    } else if (mood == RobotMood.drinking) {
      canvas.drawCircle(leftEye + const Offset(0, 1), 5, fillDark);
      canvas.drawCircle(rightEye + const Offset(0, 1), 5, fillDark);
    } else if (mood == RobotMood.cry) {
      canvas.drawCircle(leftEye + const Offset(0, 2), 5.5, fillDark);
      canvas.drawCircle(rightEye + const Offset(0, 2), 5.5, fillDark);
      canvas.drawLine(
        leftEye + const Offset(-6, -2),
        leftEye + const Offset(-2, 3),
        dark,
      );
      canvas.drawLine(
        rightEye + const Offset(2, -2),
        rightEye + const Offset(6, 3),
        dark,
      );
    } else if (mood == RobotMood.eating) {
      // Happy squinted eating eyes
      canvas.drawCircle(leftEye + const Offset(0, 1.5), 5.2, fillDark);
      canvas.drawCircle(rightEye + const Offset(0, 1.5), 5.2, fillDark);
    } else {
      normalEye(leftEye);
      normalEye(rightEye);
    }
    // read and catch

    // ================================
    // READING ANIMATION
    // ================================
    if (mood == RobotMood.reading) {
      // Book in front of robot
      final bookX = center.dx + 28;
      final bookY = center.dy + 12;

      // Book cover
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bookX - 18, bookY - 22, 36, 44),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.brown.shade700,
      );

      // Pages
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bookX - 14, bookY - 20, 28, 40),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white,
      );

      // Book lines (text)
      final linePaint =
          Paint()
            ..color = Colors.black.withOpacity(0.6)
            ..strokeWidth = 1.5;

      for (int i = 0; i < 5; i++) {
        canvas.drawLine(
          Offset(bookX - 10, bookY - 14 + i * 7),
          Offset(bookX + 10, bookY - 14 + i * 7),
          linePaint,
        );
      }
    }

    // ================================
    // CATCHING ANIMATION
    // ================================
    if (mood == RobotMood.catching) {
      final flyOffset = Offset(
        sin(dizzyAngle * 6) * 35,
        cos(dizzyAngle * 5) * 20 - 25,
      );

      // Draw flying insect
      final flyPos = center + flyOffset;

      // Body
      canvas.drawCircle(flyPos, 4, Paint()..color = Colors.black87);

      // Wings
      canvas.drawOval(
        Rect.fromCenter(
          center: flyPos + const Offset(-6, -3),
          width: 9,
          height: 5,
        ),
        Paint()..color = Colors.white.withOpacity(0.7),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: flyPos + const Offset(6, -3),
          width: 9,
          height: 5,
        ),
        Paint()..color = Colors.white.withOpacity(0.7),
      );

      // Eye focus lines (robot looking at fly)
      canvas.drawLine(
        center + const Offset(-18, -5),
        flyPos,
        Paint()
          ..color = Colors.redAccent.withOpacity(0.4)
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        center + const Offset(18, -5),
        flyPos,
        Paint()
          ..color = Colors.redAccent.withOpacity(0.4)
          ..strokeWidth = 1.5,
      );
    }
    // ================================
    // MOUTH + EATING ANIMATION
    // ================================
    // final mouth = Path();
    // ================================
    // MOUTH + SPECIAL MODES
    // ================================

    if (mood == RobotMood.singing) {
      final open = 6 + sin(singingProgress * pi * 3) * 6;
      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 18),
          width: 16,
          height: open,
        ),
        Paint()..color = Colors.black.withOpacity(ghostOpacity),
      );

      for (int i = 0; i < 4; i++) {
        final t = (singingProgress * 1.8 + i * 0.25) % 1.0;
        final noteX = center.dx + 14 + (t * 26) + sin(t * 8) * 4;
        final noteY = center.dy + 10 - (t * 38);
        final opacity = (1.0 - t).clamp(0.3, 1.0);

        canvas.drawCircle(
          Offset(noteX, noteY),
          3.2 - t * 1.2,
          Paint()..color = faceColor.withOpacity(opacity),
        );
        canvas.drawLine(
          Offset(noteX + 1, noteY - 5),
          Offset(noteX + 1, noteY - 14),
          Paint()..color = faceColor.withOpacity(opacity * 0.8),
        );
      }
    } else if (mood == RobotMood.smoking) {
      final mouthPos = center + const Offset(0, 18);

      canvas.drawCircle(
        mouthPos,
        4.2 + sin(smokingProgress * 5) * 0.8,
        Paint()..color = Colors.black.withOpacity(ghostOpacity * 0.9),
      );

      canvas.drawLine(
        mouthPos + const Offset(9, -1),
        mouthPos + const Offset(23, -4),
        Paint()
          ..color = const Color(0xFF8D5524)
          ..strokeWidth = 4.0
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawCircle(
        mouthPos + const Offset(24, -4.5),
        2.8,
        Paint()..color = Colors.orangeAccent.withOpacity(0.9),
      );

      for (int i = 0; i < 5; i++) {
        final t = (smokingProgress * 1.35 + i * 0.2) % 1.0;
        final drift = sin(t * 6 + i) * (7 + i);
        final smokeX = mouthPos.dx + 12 + drift;
        final smokeY = mouthPos.dy - 18 - (t * 42);
        final size = 4.5 - t * 2.8;
        final opacity = (0.55 - t * 0.5).clamp(0.05, 0.55);

        canvas.drawCircle(
          Offset(smokeX, smokeY),
          size,
          Paint()..color = Colors.white.withOpacity(opacity * ghostOpacity),
        );
      }
    } else if (mood == RobotMood.ghost) {
      final mouthPos = center + const Offset(0, 20);
      final wave = sin(ghostProgress * 11) * 3.5;

      final ghostMouth =
          Path()
            ..moveTo(mouthPos.dx - 11, mouthPos.dy + wave - 2)
            ..quadraticBezierTo(
              mouthPos.dx,
              mouthPos.dy + wave + 8 + sin(ghostProgress * 15) * 3,
              mouthPos.dx + 11,
              mouthPos.dy + wave - 2,
            );

      canvas.drawPath(
        ghostMouth,
        Paint()
          ..color = Colors.black.withOpacity(0.75 * ghostOpacity)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke,
      );
    } else if (mood == RobotMood.eating) {
      // Keep your original dynamic mouth (you liked it)
      final openAmount = 6 + (chompVal * 18);
      final mouthPath =
          Path()
            ..moveTo(center.dx - 15, center.dy + 17)
            ..quadraticBezierTo(
              center.dx,
              center.dy + 17 + openAmount,
              center.dx + 15,
              center.dy + 17,
            );
      canvas.drawPath(mouthPath, dark..strokeWidth = 3.5);

      // ==================== YOUR ORIGINAL CRUMBS (kept as-is) ====================
      for (int i = 0; i < 8; i++) {
        final seed = i * 1.7;
        final t = (chompVal * 8 + seed) % 1.0;
        final spread = sin(chompVal * 12 + seed) * 14;

        final crumbX = -12 + spread + sin(chompVal * 25 + seed * 2) * 4;
        final crumbY = 22 + (t * 28) - cos(chompVal * 18 + seed) * 8;

        final crumbSize = 2.2 + sin(chompVal * 30 + seed) * 1.1;
        final opacity = (1.0 - t * 0.85).clamp(0.2, 1.0);

        final crumbPaint =
            Paint()
              ..color = Colors.orangeAccent.withOpacity(opacity)
              ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(center.dx + crumbX, center.dy + crumbY);
        canvas.rotate(sin(chompVal * 15 + seed) * 0.8);

        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: crumbSize,
            height: crumbSize * 0.6,
          ),
          crumbPaint,
        );
        canvas.restore();
      }

      // ====================== FORK + SPOON + TOWEL ======================
      final eatProgress = chompVal;

      final towelX = center.dx - 48;
      final towelY = center.dy + 12;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(towelX, towelY, 19, 32),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.redAccent.withOpacity(0.9),
      );

      final foldPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.5)
            ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(towelX + 4, towelY + 8),
        Offset(towelX + 15, towelY + 8),
        foldPaint,
      );
      canvas.drawLine(
        Offset(towelX + 4, towelY + 16),
        Offset(towelX + 15, towelY + 16),
        foldPaint,
      );
      canvas.drawLine(
        Offset(towelX + 4, towelY + 24),
        Offset(towelX + 15, towelY + 24),
        foldPaint,
      );

      // Fork
      final forkSwing = sin(eatProgress * 6) * 4;
      final forkLift = cos(eatProgress * 5) * 6;
      final forkX = center.dx + 42 + forkSwing;
      final forkY = center.dy + 18 + forkLift;

      final forkPaint =
          Paint()
            ..color = Colors.grey[300]!
            ..strokeWidth = 3.8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(forkX + 6, forkY + 22),
        Offset(forkX + 18, forkY + 42),
        forkPaint,
      );
      canvas.drawLine(
        Offset(forkX, forkY - 2),
        Offset(forkX, forkY - 18),
        forkPaint,
      );
      canvas.drawLine(
        Offset(forkX + 6, forkY - 1),
        Offset(forkX + 6, forkY - 17),
        forkPaint,
      );
      canvas.drawLine(
        Offset(forkX + 12, forkY),
        Offset(forkX + 12, forkY - 16),
        forkPaint,
      );

      final foodY = forkY - 22 + sin(eatProgress * 8) * 5;
      canvas.drawCircle(
        Offset(forkX + 6, foodY),
        7,
        Paint()..color = Colors.deepOrangeAccent,
      );

      // Spoon
      final spoonSwing = sin(eatProgress * 4.5) * 3.5;
      final spoonX = center.dx + 52 + spoonSwing;
      final spoonY = center.dy + 25;

      final spoonPaint =
          Paint()
            ..color = Colors.grey[400]!
            ..strokeWidth = 3.5
            ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(spoonX + 5, spoonY + 18),
        Offset(spoonX + 22, spoonY + 35),
        spoonPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(spoonX + 4, spoonY - 4),
          width: 14,
          height: 11,
        ),
        Paint()..color = Colors.grey[350]!,
      );
      canvas.drawCircle(
        Offset(spoonX + 4, spoonY - 4),
        4.5,
        Paint()..color = Colors.amber.withOpacity(0.7),
      );
    } else if (mood == RobotMood.drinking) {
      // Your drinking code (kept as-is)
      final sway = sin(drinkProgress * 3.2) * 2.6;
      final strawEndX = -27.0 + sway;
      final strawEndY = 46.0 + cos(drinkProgress * 2.6) * 1.6;

      final liquidColor = _getLiquidColor(drinkEmoji);
      final strawColor = _getStrawColor(drinkEmoji);

      canvas.drawLine(
        center + const Offset(-8, 22),
        center + Offset(strawEndX, strawEndY),
        Paint()
          ..color = strawColor
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        center + const Offset(-10.5, 20.5),
        center + Offset(strawEndX - 2, strawEndY - 3),
        Paint()
          ..color = Colors.white.withOpacity(0.45)
          ..strokeWidth = 2.0,
      );

      final glassX = center.dx - 42;
      final glassY = center.dy + 29;

      final glassRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(glassX, glassY, 24, 35),
        const Radius.circular(9),
      );

      canvas.drawRRect(
        glassRect,
        Paint()..color = Colors.white.withOpacity(0.14),
      );
      canvas.drawRRect(
        glassRect,
        Paint()
          ..color = Colors.cyan.withOpacity(0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );

      final liquidHeight = 4.0 + (drinkProgress * 23.0).clamp(0.0, 23.0);
      canvas.drawRect(
        Rect.fromLTWH(
          glassX + 3.5,
          glassY + liquidHeight,
          17,
          35 - liquidHeight,
        ),
        Paint()..color = liquidColor,
      );

      final bubbleCount = (drinkEmoji == "🧋" || drinkEmoji == "🍺") ? 9 : 6;
      for (int i = 0; i < bubbleCount; i++) {
        final t = (drinkProgress * 3.8 + i * 1.4) % 1.0;
        final bx = glassX + 8.5 + sin(drinkProgress * 7 + i) * 4.0;
        final by = glassY + 26 + (t * (24 - drinkProgress * 13));
        final opacity = (0.9 - t * 0.75) * (1.0 - drinkProgress * 0.55);

        canvas.drawCircle(
          Offset(bx, by),
          1.4 + sin(drinkProgress * 10 + i) * 0.5,
          Paint()..color = Colors.white.withOpacity(opacity.clamp(0.1, 0.9)),
        );
      }

      canvas.drawRect(
        Rect.fromLTWH(glassX + 5, glassY + liquidHeight + 2, 12, 2),
        Paint()..color = Colors.white.withOpacity(0.4),
      );
    } else {
      final mouth = Path();

      if (mood == RobotMood.cool) {
        mouth.moveTo(center.dx - 12, center.dy + 18);
        mouth.quadraticBezierTo(
          center.dx + 8,
          center.dy + 13,
          center.dx + 17,
          center.dy + 19,
        );
      } else if (mood == RobotMood.lazy || mood == RobotMood.drowsy) {
        mouth.moveTo(center.dx - 14, center.dy + 23);
        mouth.quadraticBezierTo(
          center.dx,
          center.dy + 29,
          center.dx + 14,
          center.dy + 23,
        );
      } else if (mood == RobotMood.thinking) {
        mouth.moveTo(center.dx - 6, center.dy + 19);
        mouth.lineTo(center.dx + 11, center.dy + 17);
      } else if (mood == RobotMood.curious) {
        mouth.moveTo(center.dx - 13, center.dy + 19);
        mouth.quadraticBezierTo(
          center.dx - 2,
          center.dy + 25,
          center.dx + 12,
          center.dy + 19,
        );
      } else if (mood == RobotMood.distracted) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center + const Offset(0, 20),
            width: 10,
            height: 8,
          ),
          fillDark,
        );
      } else if ([
        RobotMood.happy,
        RobotMood.excited,
        RobotMood.love,
      ].contains(mood)) {
        mouth.moveTo(center.dx - 17, center.dy + 15);
        mouth.quadraticBezierTo(
          center.dx,
          center.dy + 28,
          center.dx + 17,
          center.dy + 15,
        );
      } else if (mood == RobotMood.cry) {
        mouth.moveTo(center.dx - 13, center.dy + 23);
        mouth.quadraticBezierTo(
          center.dx,
          center.dy + 27,
          center.dx + 13,
          center.dy + 23,
        );
      } else if (mood == RobotMood.dizzy) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center + const Offset(0, 19),
            width: 14,
            height: 10,
          ),
          fillDark,
        );
      } else {
        mouth.moveTo(center.dx - 13, center.dy + 19);
        mouth.lineTo(center.dx + 13, center.dy + 19);
      }

      if (mouth.computeMetrics().isNotEmpty && mood != RobotMood.eating) {
        canvas.drawPath(mouth, dark);
      }
    }

    // ================================
    // PHONE (Distracted)
    // ================================
    if (mood == RobotMood.distracted) {
      final phoneRect = Rect.fromCenter(
        center: center + const Offset(3, 55),
        width: 28,
        height: 48, // Taller for modern look
      );

      // 1. OUTER GLOW (The "OLED" bleed onto the robot's body)
      canvas.drawCircle(
        phoneRect.center,
        35,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.blueAccent.withOpacity(0.12), Colors.transparent],
          ).createShader(Rect.fromCircle(center: phoneRect.center, radius: 35)),
      );

      // 2. MAIN CHASSIS (Deep metallic finish)
      final frameRRect = RRect.fromRectAndRadius(
        phoneRect,
        const Radius.circular(8),
      );
      canvas.drawRRect(
        frameRRect,
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.grey.shade400, Colors.black, Colors.grey.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(phoneRect),
      );

      // 3. THE SCREEN
      final screenRect = phoneRect.deflate(1.5);
      final screenRRect = RRect.fromRectAndRadius(
        screenRect,
        const Radius.circular(6.5),
      );
      canvas.drawRRect(screenRRect, Paint()..color = const Color(0xFF050505));

      // 4. CHAT BUBBLES (Realistic Texting UI)
      final double chatTop = screenRect.top + 8;

      // Received Message (Dark Grey)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(screenRect.left + 3, chatTop, 14, 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF1C1C1E),
      );

      // Sent Message (Blue - iMessage style)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(screenRect.right - 17, chatTop + 7, 14, 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF007AFF),
      );

      // 5. INPUT BAR & KEYBOARD AREA
      final keyboardTop = screenRect.bottom - 15;
      canvas.drawRect(
        Rect.fromLTWH(screenRect.left, keyboardTop, screenRect.width, 15),
        Paint()..color = Colors.white.withOpacity(0.05),
      );

      // Pulsing Cursor in the input field
      if (sin(DateTime.now().millisecondsSinceEpoch / 250) > 0) {
        canvas.drawRect(
          Rect.fromLTWH(screenRect.left + 4, keyboardTop + 3, 0.6, 2.5),
          Paint()..color = Colors.blueAccent,
        );
      }

      // 6. GLASS SHEEN (High-end curved reflection)
      final sheenPath =
          Path()
            ..moveTo(screenRect.left + 15, screenRect.top)
            ..lineTo(screenRect.right, screenRect.top)
            ..lineTo(screenRect.right, screenRect.bottom - 25)
            ..close();

      canvas.drawPath(
        sheenPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white.withOpacity(0.08), Colors.transparent],
          ).createShader(screenRect),
      );

      // 7. DYNAMIC ISLAND (The Notch)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: screenRect.topCenter + const Offset(0, 3.5),
            width: 7,
            height: 2,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.black,
      );

      // 8. ANIMATED TOUCH INTERACTION (The "Tapping" Point)
      // Logic: Moves the tap point around the keyboard area to look like typing
      final double tapX =
          screenRect.left + 8 + (sin(phoneTapProgress * 15) * 6).abs();
      final double tapY =
          screenRect.bottom - 7 + (cos(phoneTapProgress * 10) * 2);
      final Offset fingerTip = Offset(tapX, tapY);

      // Expanding Ripple on tap
      double rippleVal = (phoneTapProgress * 2) % 1.0;
      canvas.drawCircle(
        fingerTip,
        6 * rippleVal,
        Paint()
          ..color = Colors.orangeAccent.withOpacity(0.4 * (1 - rippleVal))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // Solid touch point (The "Finger")
      canvas.drawCircle(
        fingerTip,
        1.2,
        Paint()
          ..color = Colors.orangeAccent
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
      );
    }

    // ================================
    // GOODBYE (Cry mood)
    // ================================
    if (mood == RobotMood.cry) {
      final handX = 52 + sin(dizzyAngle * 8) * 5;
      canvas.drawCircle(
        center + Offset(handX, 24),
        13,
        Paint()..color = Colors.amber[300]!,
      );
      canvas.drawLine(
        center + Offset(handX - 9, 16),
        center + Offset(handX + 14, 9),
        dark..strokeWidth = 7,
      );

      final bubbleRect = Rect.fromCenter(
        center: center + const Offset(55, -38),
        width: 60,
        height: 34,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bubbleRect, const Radius.circular(15)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bubbleRect, const Radius.circular(15)),
        dark..strokeWidth = 2.5,
      );

      final textPainter = TextPainter(
        text: const TextSpan(
          text: "Bye!",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, center + const Offset(34, -48));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RobotPainter oldDelegate) => true;
}

Color _getLiquidColor(String emoji) {
  switch (emoji) {
    case "☕":
    case "🍵":
      return const Color(0xFF6D4C41); // coffee/tea

    case "🍹":
    case "🍸":
      return const Color(0xFFFF4081); // cocktail

    case "🥃":
      return const Color(0xFFFFB74D); // whiskey

    case "🧋":
      return const Color(0xFF8D6E63); // bubble tea

    case "🥛":
      return const Color(0xFFF5F5F5); // milk

    case "🧃":
      return const Color(0xFFFFC107); // juice

    case "🥤":
      return const Color(0xFF81D4FA); // soda

    default:
      return const Color(0xFF81D4FA);
  }
}

Color _getStrawColor(String emoji) {
  switch (emoji) {
    case "🍹":
    case "🍸":
    case "🥃":
      return Colors.amberAccent;

    case "☕":
    case "🍵":
      return Colors.brown;

    case "🧪":
      return Colors.greenAccent;

    default:
      return Colors.grey;
  }
}
