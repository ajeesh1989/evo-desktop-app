// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:glitch_garden/controllers/robot_buddy_controller.dart';

class RobotPainter1 extends CustomPainter {
  final RobotMood mood;
  final bool blink, isNight, isSunny;
  final Color faceColor;
  final double dizzyAngle, chompVal, antennaVal;
  final double shootOffset;
  final double fallOffset;
  final Offset eyeOffset;
  final double crabX;
  final double crabY;
  final double crabTilt;
  final double drinkProgress;
  final double phoneTapProgress;
  final bool showHat;
  final bool showGlasses;
  final String drinkEmoji;
  final double walkCycle; // 0 → 1 looping
  final double danceCycle; // 0 → 1 looping
  final bool isWalking;
  final bool isDancing;
  final double singingProgress; // 0.0 → 1.0 for mouth / note animation
  final double smokingProgress; // 0.0 → 1.0 for smoke puff
  final double ghostProgress; // 0.0 → 1.0 for transparency + float
  final bool showLoveEyes;

  RobotPainter1({
    required this.mood,
    required this.blink,
    required this.faceColor,
    required this.dizzyAngle,
    required this.chompVal,
    required this.antennaVal,
    required this.isNight,
    required this.isSunny,
    required this.showHat,
    required this.showGlasses,
    required this.drinkEmoji,
    required this.showLoveEyes,
    this.shootOffset = 0,
    this.fallOffset = 0,
    this.eyeOffset = Offset.zero,
    this.drinkProgress = 0.0,
    this.phoneTapProgress = 0.0,
    this.walkCycle = 0.0,
    this.danceCycle = 0.0,
    this.isWalking = false,
    this.isDancing = false,
    this.crabX = 0,
    this.crabY = 0,
    this.crabTilt = 0,
    this.singingProgress = 0.0,
    this.smokingProgress = 0.0,
    this.ghostProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final bodyWhite = Colors.white;
    final facePlateColor = const Color(0xFF121212);
    final accentColor = faceColor;

    canvas.save();

    // Dancing + Shoot effects
    double danceMoveX = 0, danceMoveY = 0, danceTilt = 0, bodySquash = 0;
    if (isDancing) {
      final t = danceCycle * 2 * pi;
      danceMoveX = sin(t) * 14;
      danceMoveY = -((sin(t) + 1) / 2) * 10;
      danceTilt = sin(t) * 0.12;
      bodySquash = sin(t) * 2.0;
      danceMoveX += sin(t * 0.5) * 4;
      danceTilt += sin(t * 0.5) * 0.05;
    }

    double shootTilt = 0, shootMoveY = 0, shootSquash = 0;
    if (shootOffset > 0.05) {
      final t = shootOffset * 5.0;
      shootTilt = -0.45 * shootOffset;
      shootMoveY = 22 * shootOffset;
      shootSquash = sin(t * 12) * 2.5 * (1.0 - shootOffset);
    }

    final totalX = crabX + danceMoveX;
    final totalY = crabY + danceMoveY + shootMoveY;
    final totalTilt = crabTilt + danceTilt + shootTilt;

    canvas.translate(center.dx + totalX, center.dy + totalY);
    canvas.rotate(totalTilt);

    if (isDancing || shootOffset > 0.05) {
      final squashX = 1.0 + (bodySquash + shootSquash) * 0.008;
      final squashY = 1.0 - (bodySquash + shootSquash * 1.6) * 0.016;
      canvas.scale(squashX, squashY);
    }

    canvas.translate(-center.dx, -center.dy);

    // Ghost mode floating + transparency
    // Ghost mode floating + transparency (SMOOTHED)
    double ghostOpacity = 1.0;
    double ghostFloatY = 0.0;

    if (mood == RobotMood.ghost) {
      final t = ghostProgress * 2 * pi;

      ghostOpacity = 0.7 + sin(t) * 0.2; // softer fade
      ghostFloatY = sin(t * 0.8) * 6; // slower float

      canvas.translate(0, ghostFloatY);
    }
    // =============================================
    // MAKE ENTIRE ROBOT GHOSTLY (Transparency)
    // =============================================
    final Color bodyColor = bodyWhite.withOpacity(ghostOpacity);
    final Color plateColor = facePlateColor.withOpacity(ghostOpacity * 0.98);
    final Color glowColor = accentColor.withOpacity(ghostOpacity);

    // Update paints for ghost mode
    final paintWhiteGhost = Paint()..color = bodyColor;
    final platePaintGhost = Paint()..color = plateColor;
    final glowPaintGhost =
        Paint()
          ..color = glowColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final fillGlowGhost = Paint()..color = glowColor;
    // ================================
    // GLOBAL TRANSFORM
    // ================================

    if (mood == RobotMood.reading) {
      final bookCenter = center + const Offset(0, 55);

      // 📖 Book (bigger + better aligned)
      final bookRect = Rect.fromCenter(
        center: bookCenter,
        width: 55,
        height: 34,
      );

      final rrect = RRect.fromRectAndRadius(bookRect, const Radius.circular(6));

      // draw book
      canvas.drawRRect(rrect, Paint()..color = Colors.brown.shade400);

      // spine
      canvas.drawLine(
        bookRect.centerLeft,
        bookRect.centerRight,
        Paint()
          ..color = Colors.brown.shade900
          ..strokeWidth = 2,
      );

      // page highlight
      canvas.drawLine(
        bookRect.topLeft + const Offset(6, 6),
        bookRect.topRight - const Offset(6, 6),
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..strokeWidth = 1,
      );
    }

    final paintWhite = Paint()..color = bodyWhite;
    final platePaint = Paint()..color = facePlateColor;
    final glowPaint =
        Paint()
          ..color = accentColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final fillGlow = Paint()..color = accentColor;

    // ================================
    // ANTENNA
    // ================================
    final antX = center.dx;
    final antY = center.dy - 35; // Lowered because head is shorter
    final double antennaJiggle =
        (mood == RobotMood.dizzy)
            ? sin(dizzyAngle * 12) * 10
            : sin(antennaVal * pi * 2) * 5;

    canvas.drawLine(
      Offset(antX, antY),
      Offset(antX + antennaJiggle, antY - 18),
      glowPaintGhost..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(antX + antennaJiggle, antY - 21),
      3.5,
      fillGlowGhost,
    );

    // ================================
    // BODY (Small & Cute)
    // ================================
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center:
            center + const Offset(0, 42), // Moved up slightly to follow head
        width: 55,
        height: 35, // Slightly shorter body
      ),
      const Radius.circular(15),
    );
    canvas.drawRRect(bodyRect, paintWhiteGhost); // ← Changed

    final textPainter = TextPainter(
      text: const TextSpan(
        text: "EVO",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, 38));

    // ================================
    // HEAD & FACE PLATE (HEIGHT REDUCED)
    // ================================
    // ================================
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 115, height: 72),
      const Radius.circular(28),
    );
    canvas.drawRRect(headRect, paintWhiteGhost); // ← FIXED

    final plateRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 100, height: 60),
      const Radius.circular(22),
    );
    canvas.drawRRect(
      plateRect,
      platePaintGhost,
    ); // ← Changed    // ================================
    // NIGHT CAP 🌙
    // ================================
    if (isNight && showHat) {
      // 🎨 Gradient
      final capPaint =
          Paint()
            ..shader = LinearGradient(
              colors: [Colors.green.shade900, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(
              Rect.fromCenter(
                center: center + const Offset(0, -55),
                width: 120,
                height: 70,
              ),
            );

      // 🧢 CAP BODY (now properly on TOP of head)
      final capPath = Path();
      capPath.moveTo(center.dx - 55, center.dy - 32); // sits on head top
      capPath.quadraticBezierTo(
        center.dx - 20,
        center.dy - 80, // peak
        center.dx + 25,
        center.dy - 65,
      );
      capPath.quadraticBezierTo(
        center.dx + 65,
        center.dy - 40,
        center.dx + 30,
        center.dy - 25,
      );
      capPath.quadraticBezierTo(
        center.dx - 25,
        center.dy - 22,
        center.dx - 55,
        center.dy - 32,
      );
      capPath.close();

      canvas.drawPath(capPath, capPaint);

      // 🧣 LOWER BAND (touching head properly)
      final wrap = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + const Offset(0, -28),
          width: 110,
          height: 20,
        ),
        const Radius.circular(16),
      );

      canvas.drawRRect(wrap, Paint()..color = Colors.green.shade900);

      // 🎉 TIP (hanging stylishly)
      final tipStart = center + const Offset(25, -70);
      final tipEnd =
          center +
          Offset(
            55 + sin(dizzyAngle * 3) * 2, // slight sway 🔥
            -95 + cos(dizzyAngle * 3) * 2,
          );

      final tipPaint =
          Paint()
            ..color = Colors.green.shade800
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round;

      canvas.drawLine(tipStart, tipEnd, tipPaint);

      // 🔴 Pom-pom
      canvas.drawCircle(
        tipEnd,
        6,
        Paint()..color = Colors.white.withOpacity(0.9),
      );

      // ✨ subtle highlight
      canvas.drawPath(
        capPath,
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // ================================
    // CHEEKS
    // ================================
    // ================================
    // CHEEKS
    // ================================
    if (mood == RobotMood.love || mood == RobotMood.excited) {
      final blushOpacity = mood == RobotMood.ghost ? ghostOpacity * 0.6 : 0.15;
      final blush = Paint()..color = accentColor.withOpacity(blushOpacity);

      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(-32, 10),
          width: 12,
          height: 6,
        ),
        blush,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(32, 10),
          width: 12,
          height: 6,
        ),
        blush,
      );
    }

    // ================================
    // EYES (Adjusted for shorter head)
    // ================================
    Offset leftEye = center + const Offset(-24, -6) + eyeOffset;
    Offset rightEye = center + const Offset(24, -6) + eyeOffset;

    void drawEvoEye(
      Offset pos, {
      double heightScale = 1.0,
      double widthScale = 1.0,
    }) {
      final rect = Rect.fromCenter(
        center: pos,
        width: 11 * widthScale,
        height: 16 * heightScale,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = accentColor.withOpacity(ghostOpacity),
      );
    }

    // ================================
    // CATCHING MODE - Realistic Flying Fly + Hunting Vibes
    // ================================
    // ================================
    // CATCHING MODE - Clean & Realistic Fly
    // ================================
    // ================================
    // CATCHING MODE - Calm Eye Following (Slow & Smooth)
    // ================================
    if (mood == RobotMood.catching) {
      // 🧠 TIME (slow & natural)
      final time = dizzyAngle * 2.2;

      // 🪰 ORGANIC FLY PATH (non-repeating feel)
      final flyX =
          sin(time * 1.3) * 28 + cos(time * 0.7) * 18 + sin(time * 2.1) * 6;

      final flyY = cos(time * 1.1) * 20 + sin(time * 0.9) * 10 - 28;

      final flyPos = center + Offset(flyX, flyY);

      // 🪶 BODY
      canvas.drawCircle(
        flyPos,
        3.5,
        Paint()..color = Colors.black.withOpacity(0.9),
      );

      // 🪽 WINGS (fast + subtle flutter)
      final wingFlap = sin(time * 18) * 2.2;

      canvas.drawOval(
        Rect.fromCenter(
          center: flyPos + Offset(-4.5, -3 + wingFlap),
          width: 8,
          height: 3,
        ),
        Paint()..color = Colors.white.withOpacity(0.7),
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: flyPos + Offset(4.5, -3 - wingFlap),
          width: 8,
          height: 3,
        ),
        Paint()..color = Colors.white.withOpacity(0.7),
      );

      // 🎯 SMOOTH EYE TRACKING (THIS MAKES IT FEEL ALIVE)
      final targetOffset = Offset(
        (flyPos.dx - center.dx) * 0.16,
        (flyPos.dy - center.dy) * 0.16,
      );

      // add slight delay feeling (easing)
      final smoothDx = targetOffset.dx * 0.85;
      final smoothDy = targetOffset.dy * 0.85;

      final leftEyePos = leftEye + Offset(smoothDx, smoothDy);
      final rightEyePos = rightEye + Offset(smoothDx, smoothDy);

      drawEvoEye(leftEyePos);
      drawEvoEye(rightEyePos);

      // 🔴 SUBTLE FOCUS BEAM (premium feel)
      final focusPaint =
          Paint()
            ..color = Colors.redAccent.withOpacity(0.18)
            ..strokeWidth = 1;

      canvas.drawLine(leftEyePos, flyPos, focusPaint);
      canvas.drawLine(rightEyePos, flyPos, focusPaint);

      // ✨ OPTIONAL: tiny motion blur trail (VERY subtle, cinematic)
      for (int i = 1; i <= 3; i++) {
        final trailT = i * 0.12;
        final trailPos =
            center +
            Offset(
              sin((time - trailT) * 1.3) * 28 + cos((time - trailT) * 0.7) * 18,
              cos((time - trailT) * 1.1) * 20 - 28,
            );

        canvas.drawCircle(
          trailPos,
          2.2 - i * 0.5,
          Paint()..color = Colors.black.withOpacity(0.08),
        );
      }
    }

    // ================================
    // EYES + GLASSES LOGIC
    // ================================

    // 🕶️ 1. COOL MODE (bold glasses)
    // ================================
    // EYES + GLASSES LOGIC (FIXED PRIORITY)
    // ================================

    // ================================
    // READING MODE - Made it look REAL & Cute
    // ================================
    // ================================
    // EYES + GLASSES LOGIC
    // ================================

    // SLEEP MODE - Eyes properly closed
    // SLEEP MODE - Eyes properly closed
    if (mood == RobotMood.sleep) {
      final closedPaint =
          Paint()
            ..color = accentColor.withOpacity(0.85)
            ..strokeWidth = 4.0
            ..style = PaintingStyle.stroke;

      final leftClosed =
          Path()
            ..moveTo(leftEye.dx - 9, leftEye.dy - 1)
            ..quadraticBezierTo(
              leftEye.dx,
              leftEye.dy + 8,
              leftEye.dx + 9,
              leftEye.dy - 1,
            );

      final rightClosed =
          Path()
            ..moveTo(rightEye.dx - 9, rightEye.dy - 1)
            ..quadraticBezierTo(
              rightEye.dx,
              rightEye.dy + 8,
              rightEye.dx + 9,
              rightEye.dy - 1,
            );

      canvas.drawPath(leftClosed, closedPaint);
      canvas.drawPath(rightClosed, closedPaint);

      final blush = Paint()..color = accentColor.withOpacity(0.12);
      canvas.drawOval(
        Rect.fromCenter(
          center: leftEye + const Offset(0, 9),
          width: 13,
          height: 5,
        ),
        blush,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: rightEye + const Offset(0, 9),
          width: 13,
          height: 5,
        ),
        blush,
      );
    }
    // HURT / SHOT expression
    else if (shootOffset > 0.05) {
      // One eye smaller + shifted (looks hit)
      drawEvoEye(leftEye, heightScale: 0.55, widthScale: 0.75);
      drawEvoEye(rightEye + const Offset(3, 4));

      // Pain / dizzy lines
      final painPaint =
          Paint()
            ..color = accentColor.withOpacity(0.7)
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke;

      canvas.drawLine(
        leftEye + const Offset(-8, -11),
        leftEye + const Offset(6, -7),
        painPaint,
      );
      canvas.drawLine(
        rightEye + const Offset(-6, -12),
        rightEye + const Offset(7, -9),
        painPaint,
      );
    }
    // READING MODE
    else if (mood == RobotMood.reading) {
      final focusShift = const Offset(0, 8);
      drawEvoEye(leftEye + focusShift, heightScale: 0.65);
      drawEvoEye(rightEye + focusShift, heightScale: 0.65);

      // === Your existing book drawing code stays here ===
      final bookCenter = center + const Offset(38, 28);

      final bookRect = Rect.fromCenter(
        center: bookCenter,
        width: 52,
        height: 38,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bookRect, const Radius.circular(6)),
        Paint()..color = const Color(0xFF8D5524),
      );

      final pageRect = bookRect.deflate(6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pageRect, const Radius.circular(4)),
        Paint()..color = Colors.white,
      );

      final linePaint =
          Paint()
            ..color = Colors.black.withOpacity(0.55)
            ..strokeWidth = 1.2;

      for (int i = 0; i < 6; i++) {
        final y = pageRect.top + 8 + (i * 5.2);
        canvas.drawLine(
          Offset(pageRect.left + 6, y),
          Offset(pageRect.right - 8, y),
          linePaint,
        );
      }

      canvas.drawRect(
        Rect.fromLTWH(bookCenter.dx + 18, bookCenter.dy - 12, 4, 24),
        Paint()..color = Colors.redAccent,
      );

      canvas.drawCircle(
        bookCenter + const Offset(-18, -14),
        2.5,
        Paint()..color = Colors.white.withOpacity(0.9),
      );

      // Squint lines
      canvas.drawLine(
        leftEye + focusShift + const Offset(-6, -2),
        leftEye + focusShift + const Offset(6, -2),
        glowPaint..strokeWidth = 2.2,
      );
      canvas.drawLine(
        rightEye + focusShift + const Offset(-6, -2),
        rightEye + focusShift + const Offset(6, -2),
        glowPaint..strokeWidth = 2.2,
      );
    }
    // COOL MODE glasses
    else if (mood == RobotMood.cool) {
      final framePaint =
          Paint()
            ..color = Colors.black
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;

      final glassPaint = Paint()..color = Colors.orange.withOpacity(0.6);

      final leftFrame = RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftEye, width: 30, height: 20),
        const Radius.circular(6),
      );

      final rightFrame = RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightEye, width: 30, height: 20),
        const Radius.circular(6),
      );

      canvas.drawRRect(leftFrame, glassPaint);
      canvas.drawRRect(rightFrame, glassPaint);
      canvas.drawRRect(leftFrame, framePaint);
      canvas.drawRRect(rightFrame, framePaint);

      canvas.drawLine(
        leftEye + const Offset(15, 0),
        rightEye - const Offset(15, 0),
        framePaint,
      );
    }
    // SUNNY AVIATOR GLASSES
    else if (isSunny && showGlasses) {
      drawEvoEye(leftEye);
      drawEvoEye(rightEye);

      final glassPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.cyan.withOpacity(0.10);

      final framePaint =
          Paint()
            ..color = Colors.white.withOpacity(0.05)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;

      Path createAviatorPath(Offset c) {
        final path = Path();
        path.moveTo(c.dx - 14, c.dy - 8);
        path.quadraticBezierTo(c.dx, c.dy - 12, c.dx + 14, c.dy - 8);
        path.lineTo(c.dx + 16, c.dy + 2);
        path.quadraticBezierTo(c.dx + 14, c.dy + 14, c.dx, c.dy + 16);
        path.quadraticBezierTo(c.dx - 14, c.dy + 14, c.dx - 16, c.dy + 2);
        path.close();
        return path;
      }

      final leftPath = createAviatorPath(leftEye);
      final rightPath = createAviatorPath(rightEye);

      canvas.drawPath(leftPath, glassPaint);
      canvas.drawPath(rightPath, glassPaint);
      canvas.drawPath(leftPath, framePaint);
      canvas.drawPath(rightPath, framePaint);

      canvas.drawLine(
        leftEye + const Offset(8, -9),
        rightEye + const Offset(-8, -9),
        framePaint,
      );
      canvas.drawLine(
        leftEye + const Offset(12, -2),
        rightEye + const Offset(-12, -2),
        framePaint,
      );
    }
    // THINKING & CURIOUS
    else if (mood == RobotMood.thinking) {
      drawEvoEye(leftEye, heightScale: 0.6, widthScale: 0.8);
      drawEvoEye(rightEye);
    } else if (mood == RobotMood.curious) {
      drawEvoEye(leftEye + const Offset(0, -3));
      drawEvoEye(rightEye + const Offset(0, 3));
    }
    // 👻 GHOST MODE - Spooky Eyes
    else if (mood == RobotMood.ghost) {
      // Spooky faded + slightly wobbly eyes
      final ghostEyeOffset = Offset(
        sin(ghostProgress * 12) * 1.2,
        cos(ghostProgress * 8) * 0.8,
      );

      drawEvoEye(leftEye + ghostEyeOffset, heightScale: 0.75, widthScale: 0.65);
      drawEvoEye(
        rightEye + ghostEyeOffset,
        heightScale: 0.75,
        widthScale: 0.65,
      );

      // Extra spooky glow around eyes
      final spookyGlow =
          Paint()
            ..color = Colors.cyanAccent.withOpacity(0.25 * ghostOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: leftEye + ghostEyeOffset,
            width: 18,
            height: 22,
          ),
          const Radius.circular(6),
        ),
        spookyGlow,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rightEye + ghostEyeOffset,
            width: 18,
            height: 22,
          ),
          const Radius.circular(6),
        ),
        spookyGlow,
      );
    }
    // DEFAULT NORMAL EYES (for all other moods)
    // 📱 DISTRACTED - Eyes follow phone (REALISTIC)
    else if (mood == RobotMood.distracted) {
      final phoneCenter = center + const Offset(0, 46);

      // Direction from eyes → phone
      final dx = phoneCenter.dx - center.dx;
      final dy = phoneCenter.dy - center.dy;

      // Normalize (prevents extreme movement)
      final distance = sqrt(dx * dx + dy * dy);
      final normX = dx / (distance == 0 ? 1 : distance);
      final normY = dy / (distance == 0 ? 1 : distance);

      // 👀 Controlled eye movement (natural limit)
      final maxMove = 15.0;
      final lookOffset = Offset(normX * maxMove, normY * maxMove);

      // ✨ Micro movement (alive feeling)
      final micro = Offset(
        sin(phoneTapProgress * 6) * 0.6,
        cos(phoneTapProgress * 5) * 0.4,
      );

      final finalOffset = lookOffset + micro;

      final leftLook = leftEye + finalOffset;
      final rightLook = rightEye + finalOffset;

      // Draw eyes looking at phone
      drawEvoEye(leftLook, heightScale: 0.9);
      drawEvoEye(rightLook, heightScale: 0.9);

      // 🔵 Subtle focus lines (premium detail)
      final focusPaint =
          Paint()
            ..color = Colors.blueAccent.withOpacity(0.12)
            ..strokeWidth = 1;

      canvas.drawLine(leftLook, phoneCenter, focusPaint);
      canvas.drawLine(rightLook, phoneCenter, focusPaint);
    }
    // DEFAULT
    else if (mood != RobotMood.catching && mood != RobotMood.ghost) {
      drawEvoEye(leftEye);
      drawEvoEye(rightEye);
    }

    // ================================
    // ================================
    // MOUTH / EATING / DRINKING (5-Star Hotel Luxury Style)
    // ================================
    // ================================
    // MOUTH - SLEEP, SHOOT, EAT, DRINK, etc.
    // ================================
    final mouthPos = center + const Offset(0, 16);

    // 1. SLEEPING MOUTH - Peaceful & cute
    if (mood == RobotMood.sleep) {
      // Soft relaxed sleeping mouth
      final sleepPath =
          Path()
            ..moveTo(mouthPos.dx - 7, mouthPos.dy + 1)
            ..quadraticBezierTo(
              mouthPos.dx,
              mouthPos.dy + 6,
              mouthPos.dx + 7,
              mouthPos.dy + 1,
            );

      canvas.drawPath(
        sleepPath,
        Paint()
          ..color = accentColor.withOpacity(0.8)
          ..strokeWidth = 2.8
          ..style = PaintingStyle.stroke,
      );

      // Tiny breathing highlight
      final breath = sin(antennaVal * 8) * 0.7;
      canvas.drawOval(
        Rect.fromCenter(
          center: mouthPos + Offset(0, 4.5 + breath),
          width: 5.5,
          height: 2.2,
        ),
        Paint()..color = Colors.white.withOpacity(0.3),
      );
    }
    // 2. SHOOT / HURT MOUTH - "Ouch!" expression
    else if (shootOffset > 0.05) {
      // Open shocked/pain mouth
      final hurtPath =
          Path()
            ..moveTo(mouthPos.dx - 8, mouthPos.dy + 4)
            ..quadraticBezierTo(
              mouthPos.dx,
              mouthPos.dy + 13,
              mouthPos.dx + 8,
              mouthPos.dy + 4,
            );

      canvas.drawPath(
        hurtPath,
        Paint()
          ..color = const Color(0xFFFF5252).withOpacity(0.95)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke,
      );

      // Inner mouth shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: mouthPos + const Offset(0, 8),
          width: 5,
          height: 6,
        ),
        Paint()..color = Colors.black.withOpacity(0.4),
      );
    }
    // 3. EATING MODE (your original luxury code)
    else if (mood == RobotMood.eating) {
      final openAmount = 4 + (chompVal * 9);
      canvas.drawOval(
        Rect.fromCenter(center: mouthPos, width: 12, height: openAmount),
        fillGlow,
      );

      canvas.drawOval(
        Rect.fromCenter(center: mouthPos, width: 7.5, height: openAmount * 0.7),
        Paint()..color = Colors.black.withOpacity(0.45),
      );

      // Food particles
      for (int i = 0; i < 4; i++) {
        final t = (chompVal * 4.5 + i) % 1.0;
        final x = mouthPos.dx - 7 + sin(chompVal * 12 + i * 2) * 11;
        final y = mouthPos.dy + 7 + (t * 22);

        canvas.drawCircle(
          Offset(x, y),
          1.8,
          Paint()..color = const Color(0xFFFFC107).withOpacity((1 - t) * 0.75),
        );
      }

      // ====================== 5-STAR DINING ACCESSORIES ======================
      final eatT = chompVal;

      // Napkin
      final napkinX = center.dx - 49;
      final napkinY = center.dy + 15;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(napkinX, napkinY, 19, 29),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFF8F8F8),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(napkinX + 1.5, napkinY + 1.5, 16, 26),
          const Radius.circular(3),
        ),
        Paint()
          ..color = const Color(0xFFD4AF37)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Fork & Spoon code (keeping your original)
      final forkSwing = sin(eatT * 3.2) * 2.8;
      final forkLift = cos(eatT * 2.8) * 3.5;
      final forkX = center.dx + 39 + forkSwing;
      final forkY = center.dy + 19 + forkLift;

      final silverPaint =
          Paint()
            ..color = const Color(0xFFEEEEEE)
            ..strokeWidth = 3.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(forkX + 7, forkY + 19),
        Offset(forkX + 18, forkY + 36),
        silverPaint,
      );
      canvas.drawLine(
        Offset(forkX, forkY - 3),
        Offset(forkX, forkY - 17),
        silverPaint,
      );
      canvas.drawLine(
        Offset(forkX + 5, forkY - 2.5),
        Offset(forkX + 5, forkY - 16),
        silverPaint,
      );
      canvas.drawLine(
        Offset(forkX + 10, forkY - 2),
        Offset(forkX + 10, forkY - 15),
        silverPaint,
      );

      final foodY = forkY - 21 + sin(eatT * 4) * 2.5;
      canvas.drawCircle(
        Offset(forkX + 5, foodY),
        5.5,
        Paint()..color = const Color(0xFFFFAB40),
      );

      // Spoon (your original code)
      final spoonSwing = sin(eatT * 2.6) * 3.2;
      final spoonX = center.dx + 50 + spoonSwing;
      final spoonY = center.dy + 24;

      canvas.drawLine(
        Offset(spoonX + 6, spoonY + 15),
        Offset(spoonX + 20, spoonY + 31),
        silverPaint..strokeWidth = 3.2,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(spoonX + 3.5, spoonY - 2),
          width: 13.5,
          height: 9.5,
        ),
        Paint()..color = const Color(0xFFEEEEEE),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(spoonX + 3.5, spoonY - 1.5),
          width: 7.5,
          height: 5,
        ),
        Paint()..color = const Color(0xFF8D6E63).withOpacity(0.85),
      );
    } else if (mood == RobotMood.singing) {
      final open =
          5 + sin(singingProgress * pi * 3) * 5.5; // more expressive open/close

      // Mouth - nice rounded singing shape
      canvas.drawOval(
        Rect.fromCenter(center: mouthPos, width: 15, height: open),
        fillGlow,
      );

      // Inner mouth shadow for depth
      canvas.drawOval(
        Rect.fromCenter(
          center: mouthPos + Offset(0, 2),
          width: 9,
          height: open * 0.65,
        ),
        Paint()..color = Colors.black.withOpacity(0.35),
      );

      // Music notes floating up (3–4 notes with different timing/sizes)
      for (int i = 0; i < 4; i++) {
        final t = (singingProgress * 1.8 + i * 0.25) % 1.0;
        final noteX = mouthPos.dx + 12 + (t * 28) + sin(t * 8) * 3;
        final noteY = mouthPos.dy - 18 - (t * 42);

        final noteOpacity = (1.0 - t) * 0.95;

        // Note head
        canvas.drawCircle(
          Offset(noteX, noteY),
          2.8 - t * 0.8,
          Paint()..color = accentColor.withOpacity(noteOpacity),
        );

        // Music note stem + flag (simple)
        canvas.drawLine(
          Offset(noteX + 1.5, noteY - 4),
          Offset(noteX + 1.5, noteY - 13),
          Paint()
            ..color = accentColor.withOpacity(noteOpacity * 0.8)
            ..strokeWidth = 1.2,
        );
      }
    } else if (mood == RobotMood.drinking) {
      // ================================
      // DRINKING - Glass starts FULL and slowly empties
      // ================================

      final sway = sin(drinkProgress * 3.2) * 2.6;
      final strawEndX = -27.0 + sway;
      final strawEndY = 46.0 + cos(drinkProgress * 2.6) * 1.6;

      final liquidColor = _getLiquidColor(drinkEmoji);
      final strawColor = _getStrawColor(drinkEmoji);

      // STRAW
      canvas.drawLine(
        center + const Offset(-8, 22),
        center + Offset(strawEndX, strawEndY),
        Paint()
          ..color = strawColor
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round,
      );

      // Straw highlight
      canvas.drawLine(
        center + const Offset(-10.5, 20.5),
        center + Offset(strawEndX - 2, strawEndY - 3),
        Paint()
          ..color = Colors.white.withOpacity(0.45)
          ..strokeWidth = 2.0,
      );

      // GLASS
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

      // Liquid starts FULL (at drinkProgress = 0) and empties as progress increases
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

      // Bubbles
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

      // Liquid surface highlight
      canvas.drawRect(
        Rect.fromLTWH(glassX + 5, glassY + liquidHeight + 2, 12, 2),
        Paint()..color = Colors.white.withOpacity(0.4),
      );
    } else if (mood == RobotMood.smoking) {
      // Mouth - slightly pursed (cool/vibing look)
      final mouthSize =
          3.5 + sin(smokingProgress * 6) * 0.6; // gentle inhale/exhale
      canvas.drawCircle(
        mouthPos,
        mouthSize,
        Paint()..color = accentColor.withOpacity(0.92),
      );

      // Cigarette (simple but cute)
      final cigX = mouthPos.dx + 11;
      final cigY = mouthPos.dy + 1;
      canvas.drawLine(
        Offset(cigX, cigY),
        Offset(cigX + 14, cigY - 2),
        Paint()
          ..color = const Color(0xFF8D5524)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
      // Cigarette glow tip
      canvas.drawCircle(
        Offset(cigX + 15, cigY - 2.5),
        2.2,
        Paint()..color = Colors.orangeAccent.withOpacity(0.85),
      );

      // Improved smoke puffs (more volume, layered, drifting naturally)
      for (int i = 0; i < 6; i++) {
        final t = (smokingProgress * 1.4 + i * 0.17) % 1.0;
        final drift = sin(t * 5 + i) * (6 + i * 1.5);
        final smokeX = mouthPos.dx + 8 + drift;
        final smokeY = mouthPos.dy - 12 - (t * 38);

        final size = 3.8 - t * 2.4;
        final opacity = (0.45 - t * 0.38).clamp(0.0, 0.45);

        canvas.drawCircle(
          Offset(smokeX, smokeY),
          size,
          Paint()..color = Colors.white.withOpacity(opacity),
        );

        // Second softer layer for thicker smoke
        if (i % 2 == 0) {
          canvas.drawCircle(
            Offset(smokeX + 3, smokeY - 4),
            size * 0.75,
            Paint()..color = Colors.white.withOpacity(opacity * 0.6),
          );
        }
      }
    }
    // 👻 GHOST MODE - Wavy Spooky Mouth
    else if (mood == RobotMood.ghost) {
      final wave = sin(ghostProgress * 11) * 3.0;
      final ghostMouthY = mouthPos.dy + wave;

      final ghostMouthPath =
          Path()
            ..moveTo(mouthPos.dx - 10, ghostMouthY - 2)
            ..quadraticBezierTo(
              mouthPos.dx,
              ghostMouthY + 7 + sin(ghostProgress * 15) * 3,
              mouthPos.dx + 10,
              ghostMouthY - 2,
            );

      canvas.drawPath(
        ghostMouthPath,
        Paint()
          ..color = accentColor.withOpacity(0.8 * ghostOpacity)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke,
      );

      // Extra inner "void" glow
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(mouthPos.dx, ghostMouthY + 4),
          width: 7,
          height: 5,
        ),
        Paint()..color = Colors.white.withOpacity(0.18 * ghostOpacity),
      );
    }
    // 6. CURIOUS / DIZZY
    // 6. CURIOUS / DIZZY
    else if (mood == RobotMood.curious || mood == RobotMood.dizzy) {
      canvas.drawCircle(mouthPos, 3.5, fillGlow);
    }
    // 7. DEFAULT NORMAL MOUTH
    else if (mood != RobotMood.ghost) {
      // ← Add this condition
      canvas.drawCircle(
        mouthPos,
        1.5 + sin(dizzyAngle * 4) * 0.5,
        Paint()..color = accentColor.withOpacity(0.25),
      );
    }

    // ❌ NO default mouth anymore (this is the key change)

    // ================================
    // ACCESSORIES
    // ================================
    if (mood == RobotMood.cry) {
      // ================================
      // SAD EYES (override look)
      // ================================
      final sadEyePaint =
          Paint()
            ..color = accentColor.withOpacity(0.7)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;

      canvas.drawLine(
        leftEye - const Offset(8, -2),
        leftEye + const Offset(8, 2),
        sadEyePaint,
      );
      canvas.drawLine(
        rightEye - const Offset(8, 2),
        rightEye + const Offset(8, -2),
        sadEyePaint,
      );

      // ================================
      // TEARS (animated)
      // ================================
      final tearOffset = sin(phoneTapProgress * 4) * 6;

      void drawTear(Offset start) {
        final tearPath =
            Path()
              ..moveTo(start.dx, start.dy)
              ..quadraticBezierTo(
                start.dx - 2,
                start.dy + 4,
                start.dx,
                start.dy + 10 + tearOffset,
              )
              ..quadraticBezierTo(
                start.dx + 2,
                start.dy + 4,
                start.dx,
                start.dy,
              );

        canvas.drawPath(
          tearPath,
          Paint()..color = Colors.cyanAccent.withOpacity(0.7),
        );
      }

      drawTear(leftEye + const Offset(0, 6));
      drawTear(rightEye + const Offset(0, 6));

      // ================================
      // MOUTH (sad curve)
      // ================================
      final sadMouth =
          Path()
            ..moveTo(mouthPos.dx - 7, mouthPos.dy + 2)
            ..quadraticBezierTo(
              mouthPos.dx,
              mouthPos.dy - 5,
              mouthPos.dx + 7,
              mouthPos.dy + 2,
            );

      canvas.drawPath(sadMouth, glowPaint);

      // ================================
      // SPEECH BUBBLE (improved)
      // ================================
      final bubbleRect = Rect.fromCenter(
        center: center + const Offset(55, -38),
        width: 52,
        height: 28,
      );

      final bubble = RRect.fromRectAndRadius(
        bubbleRect,
        const Radius.circular(12),
      );

      // Bubble background
      canvas.drawRRect(bubble, Paint()..color = Colors.white.withOpacity(0.95));

      // Bubble tail
      final tail =
          Path()
            ..moveTo(bubbleRect.left + 8, bubbleRect.bottom)
            ..lineTo(bubbleRect.left + 16, bubbleRect.bottom)
            ..lineTo(bubbleRect.left + 10, bubbleRect.bottom + 8)
            ..close();

      canvas.drawPath(tail, Paint()..color = Colors.white.withOpacity(0.95));

      // Text: more emotional
      final byePainter = TextPainter(
        text: const TextSpan(
          text: "Bye...",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      byePainter.paint(
        canvas,
        bubbleRect.center - Offset(byePainter.width / 2, byePainter.height / 2),
      );
    }
    if (mood == RobotMood.distracted) {
      final phoneRect = Rect.fromCenter(
        center: center + const Offset(0, 46),
        width: 28,
        height: 48,
      );

      // 1. SCREEN GLOW (Subtle light reflection on the robot)
      canvas.drawCircle(
        phoneRect.center,
        32,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.blueAccent.withOpacity(0.12), Colors.transparent],
          ).createShader(Rect.fromCircle(center: phoneRect.center, radius: 32)),
      );

      // 2. PREMIUM METAL CHASSIS
      canvas.drawRRect(
        RRect.fromRectAndRadius(phoneRect, const Radius.circular(8)),
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
      canvas.drawRRect(screenRRect, Paint()..color = const Color(0xFF010101));

      // 4. CHAT BUBBLES (Realistic Messaging UI)
      final double chatTop = screenRect.top + 8;

      // Received Bubble (Dark Grey)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(screenRect.left + 3, chatTop, 14, 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF1C1C1E),
      );

      // Sent Bubble (iMessage Blue)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(screenRect.right - 17, chatTop + 7, 14, 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF007AFF),
      );

      // 5. INPUT BAR & KEYBOARD AREA
      final keyboardTop = screenRect.bottom - 15;

      // Faint Keyboard Background
      canvas.drawRect(
        Rect.fromLTWH(screenRect.left, keyboardTop, screenRect.width, 15),
        Paint()..color = Colors.white.withOpacity(0.05),
      );

      // Text Input Pill
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            screenRect.left + 2,
            keyboardTop + 2,
            screenRect.width - 4,
            4,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.white10,
      );

      // Pulsing Cursor
      if (sin(DateTime.now().millisecondsSinceEpoch / 250) > 0) {
        canvas.drawRect(
          Rect.fromLTWH(screenRect.left + 4, keyboardTop + 3, 0.6, 2),
          Paint()..color = Colors.blueAccent,
        );
      }

      // 6. REALISTIC GLASS REFLECTION (Diagonal Sheen)
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

      // 8. ANIMATED FINGER INTERACTION
      // We move the "tap" point based on the progress to simulate typing letters
      final double tapX =
          screenRect.left + 6 + (sin(phoneTapProgress * 15) * 6).abs();
      final double tapY =
          screenRect.bottom - 6 + (cos(phoneTapProgress * 10) * 2);
      final Offset fingerTip = Offset(tapX, tapY);

      // Ripple (Fades out as it expands)
      double rippleVal = (phoneTapProgress * 2) % 1.0;
      canvas.drawCircle(
        fingerTip,
        6 * rippleVal,
        Paint()
          ..color = Colors.orangeAccent.withOpacity(0.3 * (1 - rippleVal))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // Touch Point (The fingertip focus)
      canvas.drawCircle(
        fingerTip,
        1.2,
        Paint()
          ..color = Colors.orangeAccent
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RobotPainter1 oldDelegate) => true;
}

Color _getLiquidColor(String emoji) {
  switch (emoji) {
    case "☕":
    case "🍵":
      return const Color(0xFF6D4C41);

    case "🍹":
    case "🍸":
      return const Color(0xFFFF4081);

    case "🥃":
      return const Color(0xFFFFB74D);

    case "🧋":
      return const Color(0xFF8D6E63);

    case "🥛":
      return const Color(0xFFF5F5F5);

    case "🧃":
      return const Color(0xFFFFC107);

    case "🥤":
      return const Color(0xFF81D4FA);

    case "🧪":
      return const Color(0xFF00E676);

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
