## 🚀 Download Evo

👉 [Download Latest Release](https://github.com/ajeesh1989/evo-desktop-app/releases/latest)

Install like a normal Windows app.

# evo-desktop-app

🧠 Evo – Desktop Robot Companion
A living, interactive desktop character built with Flutter
🚀 Overview

Evo is a highly interactive desktop companion designed to bring personality and intelligence to the user’s workspace. Unlike traditional widgets, Evo behaves like a living character — reacting dynamically to user input, system state, and environmental context such as time of day.

Built entirely using Flutter for Windows, Evo demonstrates how far custom rendering, animation systems, and system integration can be pushed to create a playful yet technically rich desktop experience.

💡 Concept & Idea

Modern desktops are functional but emotionally flat.

Evo was designed to explore:

Can a desktop app feel alive?
Can system feedback (like battery, time, inactivity) be turned into personality?
Can interactions go beyond clicks into something more playful and human-like?

The result is Evo — a reactive digital companion that:

Talks
Feels
Sleeps
Gets tired
Responds to you
✨ Core Features
🤖 Dynamic Robot Personality System

Evo operates on a multi-state mood engine, allowing it to shift behavior and visuals in real time.

Supported moods include:

Happy 😊
Excited 🎉
Love ❤️
Angry 😠
Dizzy 😵
Sleep 😴
Sick 🤒
Eating 🍴
Drowsy 😪

Each mood affects:

Facial expressions
Body animations
Interaction responses
System behavior

All transitions are smoothly animated, creating a lifelike feel rather than abrupt UI changes.

🖱️ Rich User Interaction Model

Evo is not just clickable — it is fully interactive.

Supported interactions:

Single tap → shows battery status 🔋
Double tap → excitement reaction 🎉
Triple tap → triggers “shoot mode” 🔫
Drag → move Evo anywhere on screen
Scroll → resize Evo dynamically
Right-click → context menu (jokes, sleep, wake, exit)

This creates a multi-layered interaction system similar to game-like behavior.

🍔 Interactive Feeding System (Unique Feature)

One of Evo’s most distinctive features.

Users can:

Drag & drop files directly onto Evo
Evo reacts by “eating” the file 🤖🍴
Displays playful response: “Mmm! Data tastes like chicken! 💾”
Temporarily switches into eating mode with animation

This transforms a standard desktop action into a fun, character-driven interaction, making Evo feel truly alive.

🔋 Battery Awareness & System Integration

Evo connects to real system data using battery_plus.

Behavior changes dynamically based on battery:

🔻 Low battery → becomes tired and sleepy
⚡ Charging → becomes energetic and happy
🔋 Full battery → suggests unplugging

At very low battery:

Evo automatically falls asleep
Displays a digital clock while sleeping
Triggers sleep animations and snoring effects

This creates a context-aware companion, not just a static UI.

⏰ Intelligent Idle System

Evo reacts to user inactivity:

Active → Normal behavior
Idle → Becomes drowsy
Long idle → Falls asleep

During sleep:

Plays snoring animations 💭
Shows floating “Zzz” effects
Displays a minimal digital clock UI

It also:

Randomly tells jokes
Seeks attention if ignored
Speaks contextual messages

This builds a sense of presence and continuity.

🎨 Fully Custom Rendered UI (No Images)

Evo is rendered entirely using CustomPainter.

No PNGs. No SVGs. No assets.

Everything is drawn programmatically:

Face structure
Eyes, mouth, expressions
Hands and movement
Antenna animations

Additional visual intelligence:

🌙 Night mode (sleep cap appears)
☀️ Sunny mode (sunglasses appear)
💫 Animated glow effects

This approach ensures:

High performance
Infinite customization
Smooth animation blending
🎉 Fun & Expressive Behaviors

Evo includes playful micro-interactions:

🎊 Confetti explosion when excited
😵 Dizzy spinning animation
💬 Speech bubbles with jokes & messages
🔫 “Shoot mode” (triggered via triple tap)
🤝 Hover-based emotional reactions
📂 Drag-and-drop reactions

These features elevate Evo from a tool to an experience.

🏗 Architecture & Technical Design

Evo follows a controller-driven architecture:

🔧 State Management
Centralized via RobotBuddyController
Uses ChangeNotifier for reactive UI updates
🎞 Animation System
Multiple AnimationControllers for:
Idle breathing
Jumping
Glow effects
Snoring
Falling / shooting
Combined using Listenable.merge for efficiency
🧠 Behavior Engine
Timer-based state transitions:
Idle detection
Sleep triggers
Random speech generation
Event-driven responses:
Tap gestures
Drag events
Battery updates
🖼 Rendering Engine
Built with CustomPainter
Modular drawing system:
Head
Eyes
Hands
Expressions
Dynamic positioning & animation blending
🛠 Tech Stack
Flutter (Windows Desktop)
Dart
CustomPainter → UI rendering
window_manager → frameless draggable window
battery_plus → system battery integration
AnimationControllers → advanced animations
📦 Distribution & Installer

Evo is packaged as a professional desktop application using Inno Setup.

Installer Features:
Custom app icon
Start Menu shortcut
Desktop installation flow
Built-in uninstaller
Clean installation experience

Users can install Evo just like any native Windows application.

🎯 Key Highlights
Fully interactive desktop companion
Game-like behavior implemented in Flutter
Zero image-based UI (pure rendering)
Deep system integration (battery + time)
Unique drag-to-feed interaction
Rich animation system with multiple states
🔮 Future Enhancements
🤖 AI-powered conversations (LLM integration)
🗣 Voice interaction (speech-to-text / TTS)
🌐 Online personality updates
🎭 Custom skins/themes
📊 Productivity insights (usage tracking)
🧠 Conclusion

Evo is more than a desktop widget — it’s an experiment in making software feel alive.

It combines:

Creative interaction design
Real-time system awareness
Advanced animation techniques
Custom rendering

to deliver a playful, engaging, and technically rich desktop experience.
