// robot_buddy_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:glitch_garden/controllers/robot_sound_manager.dart';
import 'package:glitch_garden/ui/camera_screen.dart';
import 'package:glitch_garden/ui/radial_context.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:window_manager/window_manager.dart';

enum RobotMood {
  happy,
  excited,
  love,
  annoyed,
  angry,
  cry,
  dizzy,
  sleep,
  eating,
  drowsy,
  sick,
  thinking,
  cool,
  lazy,
  distracted,
  curious, // Correct spelling
  walking,
  drinking,
  pizzaParty,
  reading,
  catching,
  dance,
  singing, // ← NEW
  smoking, // ← NEW
  ghost, // ← NEW
}

enum RobotCommand {
  joke,
  sleep,
  wake,
  shoot,
  exit,
  cool,
  pizza,
  drink,
  walk,
  thinking,
  lazy,
  distracted,
  curious,
  reading,
  catching,
  removeGlasses,
  removeHat,
  toggleStyle,
  camera,
  dance,
  sing, // ← NEW
  smoke, // ← NEW
  ghost, // ← NEW
  weather,
}

enum RobotPersonality {
  chill, // Relaxed & lazy
  energetic, // Hyper & excited
  sassy, // Sarcastic & confident
  shy, // Gentle & emotional
}

enum RobotCharacter { classic, evo }

enum ShootDirection { robotShootsMe, iShootRobot }

class RobotBuddyController extends ChangeNotifier {
  static final RobotBuddyController instance = RobotBuddyController._internal();
  RobotBuddyController._internal();

  // ====================== PERSONALITY SYSTEM ======================
  RobotPersonality _personality = RobotPersonality.chill;
  RobotPersonality get personality => _personality;
  RobotCharacter robotStyle = RobotCharacter.evo;
  ShootDirection _shootDirection = ShootDirection.robotShootsMe;
  ShootDirection get shootDirection => _shootDirection;
  void setRobotStyle(RobotCharacter style) {
    robotStyle = style;
    notifyListeners();
  }

  // Add this right after `RobotCharacter robotStyle = RobotCharacter.evo;`
  bool useEvoStyle = true; // ← NEW: Controls which painter to use
  String? _lastCapturedImage;
  String? get lastCapturedImage => _lastCapturedImage;
  bool _showCapturedImage = false;
  bool get showCapturedImage => _showCapturedImage;
  // Optional helper method (recommended)
  Timer? _activityLoopTimer;
  Timer? _sleepCycleTimer;
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isVoiceListening = false;
  bool get isVoiceListening => _isVoiceListening;
  bool isMuted = false;
  FlutterTts? _flutterTts;
  late AnimationController danceController;
  late Animation<double> danceValue;
  bool _showLoveEyes = false;
  bool get showLoveEyes => _showLoveEyes;
  double get singingProgress => danceValue.value; // uses dance animation

  // weather
  // ====================== WEATHER SYSTEM ======================
  String _userCity = "Kerala"; // Default fallback
  String get userCity => _userCity;

  double? _userLat;
  double? _userLon;

  String _currentWeatherSummary = "Weather not checked yet";
  String get weatherSummary => _currentWeatherSummary;

  bool _isFetchingWeather = false;

  // Set city when user says "weather in Trivandrum" etc.
  Future<void> setUserCity(String cityName) async {
    _userCity = cityName.trim();
    _userLat = null;
    _userLon = null;
    _speak("Okay! I'll now check weather for $_userCity 🌍");
    notifyListeners();

    // Fetch immediately
    await fetchAndSpeakWeather(null);
  }

  // Main real-time weather function
  // Main real-time weather function (Short & Clean)
  // Main real-time weather function - Short & Natural
  Future<void> fetchAndSpeakWeather(BuildContext? context) async {
    if (_isFetchingWeather) return;

    _isFetchingWeather = true;
    _speak("Checking weather in $_userCity... 🌡️");
    notifyListeners();

    try {
      double lat = 9.93;
      double lon = 76.27;

      // Get coordinates for custom city
      if (_userCity.toLowerCase() != "kerala" &&
          (_userLat == null || _userLon == null)) {
        final geoUrl = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(_userCity)}&count=1&language=en&format=json',
        );
        final geoRes = await http.get(geoUrl);
        if (geoRes.statusCode == 200) {
          final geoData = json.decode(geoRes.body);
          if (geoData['results'] != null && geoData['results'].isNotEmpty) {
            final r = geoData['results'][0];
            lat = r['latitude'].toDouble();
            lon = r['longitude'].toDouble();
            _userLat = lat;
            _userLon = lon;
          }
        }
      } else if (_userLat != null && _userLon != null) {
        lat = _userLat!;
        lon = _userLon!;
      }

      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code'
        '&timezone=Asia/Kolkata',
      );

      final response = await http.get(weatherUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final c = data['current'];

        final temp = c['temperature_2m'].round();
        final feels = c['apparent_temperature'].round();
        final hum = c['relative_humidity_2m'].round();
        final code = c['weather_code'];

        String condition = _getWeatherCondition(code);

        _currentWeatherSummary =
            "$temp°C • Feels $feels°C • $hum% • $condition";

        // Short & clean message for speech bubble
        final speech =
            "$_userCity: $temp°C, feels $feels°C, $hum% humidity, $condition.";

        setMood(RobotMood.curious);
        _speak(speech);

        // Short joke after a few seconds
        Future.delayed(const Duration(seconds: 4), () {
          final jokes = [
            "Humidity killing my circuits 😂",
            "Battery wants coconut water 🥥",
            "Hot & sticky today!",
          ];
          _speak(jokes[Random().nextInt(jokes.length)]);
          setMood(RobotMood.happy);
          resetIdle();
        });
      } else {
        _speak("Hot and humid in $_userCity as usual ☀️");
      }
    } catch (e) {
      print("Weather error: $e");
      _speak("Hot & humid in $_userCity right now 🌡️");
    } finally {
      _isFetchingWeather = false;
      notifyListeners();
    }
  }

  String _getWeatherCondition(int code) {
    if (code == 0) return "Clear sky";
    if (code <= 3) return "Partly cloudy";
    if (code >= 51 && code <= 67) return "Rain showers";
    if (code >= 71 && code <= 86) return "Thunderstorm possible";
    if (code >= 95) return "Thunderstorm";
    return "Cloudy";
  }

  double get smokingProgress {
    if (!_isSmoking) return 0.0;
    return (DateTime.now().millisecondsSinceEpoch % 1800) / 1800.0;
  }

  double get ghostProgress {
    if (!_isGhost) return 0.0;
    return (DateTime.now().millisecondsSinceEpoch % 2500) / 2500.0;
  }

  // SHOOT EFFECT
  double _shootOffset = 0.0;
  double get shootOffset => _shootOffset;
  late AnimationController walkController;
  late Animation<double> walkValue;

  bool _isSinging = false;
  bool get isSinging => _isSinging;

  bool _isSmoking = false;
  bool get isSmoking => _isSmoking;

  bool _isGhost = false;
  bool get isGhost => _isGhost;
  bool _isBusy = false;
  double get danceX {
    final t = danceValue.value * 2 * pi;

    // Base slow glide
    final glide = -t * 3.2;

    // Smooth step illusion
    final step = sin(t) * 5;

    // Flowing side sway (adds elegance)
    final flow = sin(t * 0.5) * 3;

    return (glide + step + flow) * 0.4 * danceIntensity;
  }

  double get danceY {
    final t = danceValue.value * 2 * pi;

    // Soft floating motion (not bounce)
    final float = sin(t * 0.8);

    return float * 2.5 * danceIntensity;
  }

  double get danceTilt {
    final t = danceValue.value * 2 * pi;

    // Smooth stylish lean (slow and controlled)
    return sin(t * 0.5) * 0.12 * danceIntensity;
  }

  double get danceScale {
    final t = danceValue.value * 2 * pi;

    // Breathing / body flow (very subtle)
    final breathe = sin(t * 0.6);

    return 1 + (breathe * 0.015 * danceIntensity);
  }

  int _dancePhase = 0;

  void toggleMute() {
    isMuted = !isMuted;
    sound.toggleMute(); // ← ADD THIS

    if (isMuted) {
      _flutterTts?.stop();
      updateSpeech("Muted 🔇");
    } else {
      updateSpeech("Unmuted 🔊");
    }
    notifyListeners();
  }

  void updateSpeech(String text, {bool show = true}) {
    _currentSpeech = text;
    _showSpeech = show;
    notifyListeners();
  }

  void hideSpeech() {
    _showSpeech = false;
    _currentSpeech = "";
    notifyListeners();
  }

  void toggleRobotStyle() {
    if (_isDancing) stopDance(); // ← Add this

    useEvoStyle = !useEvoStyle;
    final styleName = useEvoStyle ? "EVO Style" : "Classic Style";
    _speak("Switched to $styleName 🤖");
    notifyListeners();
  }

  void setPersonality(RobotPersonality newPersonality) {
    if (_personality == newPersonality) return;
    _personality = newPersonality;
    _speak(_getPersonalityGreeting());
    notifyListeners();
  }

  String _getPersonalityGreeting() {
    switch (_personality) {
      case RobotPersonality.chill:
        return "Chill mode activated 😌 Let's take it easy.";
      case RobotPersonality.energetic:
        return "ENERGY MAXED!!! ⚡ Let's gooo!";
      case RobotPersonality.sassy:
        return "Sass level: 100 💅 Ready to roast.";
      case RobotPersonality.shy:
        return "H-hi... I'll try my best today 🥺";
    }
  }

  // Personality specific jokes
  final Map<RobotPersonality, List<String>> _personalityJokes = {
    RobotPersonality.chill: [
      "I’m not lazy, I’m on power-saving mode.",
      "Why rush? Tomorrow is always there.",
      "I tried being productive once... never again.",
      "My spirit animal is a sloth sipping coconut water.",
      "Life is short. Take a nap.",
    ],
    RobotPersonality.energetic: [
      "WOOHOO!!! LET'S GOOOOO!!! 🔥",
      "I have 47 tabs open and zero regrets!",
      "Sleep? Never heard of her.",
      "I'm running on pure vibes and electricity!",
      "Blink and you'll miss me!",
    ],
    RobotPersonality.sassy: [
      "I'm not ignoring you, I'm just buffering your vibes.",
      "Error 404: Motivation not found. Try again never.",
      "Yes, I'm judging you. Silently.",
      "I'm not rude, I'm brutally honest with extra sparkle.",
      "Darling, the sass is serving today.",
    ],
    RobotPersonality.shy: [
      "Umm... do you like this joke? 🥺",
      "I hope this makes you smile...",
      "I'm trying my best to be funny...",
      "Please don't laugh too loud...",
      "You're really nice... thank you for listening.",
    ],
  };

  double get _sleepProbability {
    switch (_personality) {
      case RobotPersonality.chill:
        return 0.75;
      case RobotPersonality.energetic:
        return 0.35;
      case RobotPersonality.sassy:
        return 0.50;
      case RobotPersonality.shy:
        return 0.65;
    }
  }

  List<RobotMood> get _favoriteIdleMoods {
    switch (_personality) {
      case RobotPersonality.chill:
        return [RobotMood.lazy, RobotMood.drowsy, RobotMood.cool];
      case RobotPersonality.energetic:
        return [
          RobotMood.excited,
          RobotMood.happy,
          RobotMood.curious,
        ]; // Fixed: curios → curious
      case RobotPersonality.sassy:
        return [RobotMood.cool, RobotMood.annoyed, RobotMood.lazy];
      case RobotPersonality.shy:
        return [RobotMood.curious, RobotMood.love, RobotMood.thinking];
    }
  }

  // ====================== STATE VARIABLES ======================
  RobotMood _mood = RobotMood.happy;
  RobotMood get mood => _mood;

  bool _blink = false;
  bool get blink => _blink;

  double _scale = 1.0;
  double get scale => _scale;

  String _currentSpeech = "";
  String get currentSpeech => _currentSpeech;

  bool _showSpeech = false;
  bool get showSpeech => _showSpeech;

  bool _isSleeping = false;
  bool get isSleeping => _isSleeping;

  bool _isShooting = false;
  bool get isShooting => _isShooting;

  bool _isDown = false;
  bool get isDown => _isDown;

  bool _showDots = false;
  bool get showDots => _showDots;

  bool _isWalking = false;
  bool get isWalking => _isWalking;

  // 🦀 CRAB WALK HELPERS (ADD HERE)
  double get crabX {
    if (!_isWalking) return 0;
    return sin(walkController.value * 2 * pi) * 18;
  }

  double get crabY {
    if (!_isWalking) return 0;
    return cos(walkController.value * 2 * pi) * 4;
  }

  double get crabTilt {
    if (!_isWalking) return 0;
    return sin(walkController.value * 2 * pi) * 0.12;
  }

  Future<void> runAction(Future<void> Function() action) async {
    if (_isBusy) return;

    _isBusy = true;

    // stop idle so nothing interferes
    _activityLoopTimer?.cancel();
    _idleTimer?.cancel();

    try {
      await action();
    } finally {
      _isBusy = false;
      resetIdle(); // restart system after finishing
    }
  }

  bool _isDrinking = false;
  bool get isDrinking => _isDrinking;

  bool _isPizza = false;
  bool get isPizza => _isPizza;

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  bool _isCool = false;
  bool get isCool => _isCool;

  bool _isLazy = false;
  bool get isLazy => _isLazy;

  bool _isDistracted = false;
  bool get isDistracted => _isDistracted;

  bool _isCurious = false;
  bool get isCurious => _isCurious;

  int _batteryLevel = 100;
  int get batteryLevel => _batteryLevel;

  BatteryState _batteryState = BatteryState.full;
  BatteryState get batteryState => _batteryState;

  int _tapCount = 0;
  int _sleepTapCount = 0;

  bool _toldUnplug = false;
  bool _toldLowBattery = false;
  bool _toldVeryLowBattery = false;

  //
  bool _showGlasses = true;
  bool get showGlasses => _showGlasses;

  bool _showHat = true;
  bool get showHat => _showHat;

  Offset _eyeOffset = Offset.zero;
  Offset get eyeOffset => _eyeOffset;

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batterySubscription;

  // Timers
  Timer? _tapTimer;
  Timer? _dizzyTimer;
  Timer? _speechTimer;
  Timer? _idleTimer;
  Timer? _attentionTimer;
  Timer? _sleepTalkTimer;
  Timer? _downTimer;
  Timer? _clockTimer;

  // Animation Controllers

  bool _isDancing = false;

  final List<String> snores = ["Zz", "Zzz", "Zz…", "💤"];
  final List<String> sleepTalks = [
    "🤖💘",
    "hmm…",
    "dreaming…",
    "charging…",
    "🍉😋",

    // 😴 Funny
    "5 more minutes… pls 😴",
    "I was coding in my dream… crashed 💀",
    "Zzz… debugging life…",
    "Who ate my RAM… 🐏",
    "Loading dreams… 67%",

    // 🍔 Hungry vibes
    "🍕 mine… don’t touch…",
    "burger… extra cheese… 🤤",
    "nom nom… more fries…",
    "who stole my snack 😠",
    "dreaming of shawarma… 🌯",

    // 💘 Cute / lovely
    "stay… don’t go… 💖",
    "you’re nice… hehe 🥺",
    "I like this human… 💕",
    "warm… comfy… ☁️",
    "best nap ever…",

    // 😏 playful / flirty (safe)
    "hey… come closer… 😴",
    "don’t wake me… I’m vibing…",
    "I look cute when I sleep 😌",
    "you watching me? 👀",
    "soft mode activated… 💗",

    // 🤖 random weird robot vibes
    "beep… boop… cuddle mode…",
    "system dreaming… do not disturb…",
    "zzz… downloading happiness…",
    "low power… high dreams…",
    "error… too comfy…",

    // 😂 chaotic funny
    "I will wake up… maybe…",
    "nap > everything",
    "I love sleep… we’re dating 💀",
    "don’t update me… I’m sleeping",
    "life paused… sleeping now",
  ];
  void handleTap() {
    if (_isDown) return;

    if (_mood == RobotMood.sleep) {
      _sleepTapCount++;
      sleepShakeController.forward(from: 0);

      if (_sleepTapCount == 1) {
        sound.play('yawn');
        updateSpeech("Zzz..."); // Short text only
        return;
      }
      if (_sleepTapCount == 2) {
        updateSpeech("Mmm... 💤");
        return;
      }
      if (_sleepTapCount >= 3) {
        sound.stopLoop();
        sound.play('yawn');

        setMood(RobotMood.happy);
        _isSleeping = false;
        snoreController.stop();
        _sleepTalkTimer?.cancel();
        idleScaleController.repeat(reverse: true);

        updateSpeech("Yaaawn! ☀️");
        _sleepTapCount = 0;
        resetIdle();
        return;
      }
    }

    _sleepTapCount = 0;
    _tapCount++;
    _tapTimer?.cancel();

    _tapTimer = Timer(const Duration(milliseconds: 300), () {
      if (_tapCount >= 3) {
        shootAction();
      } else if (_tapCount == 2) {
        setMood(RobotMood.excited);
        sound.play('yay');
        updateSpeech("Woohoo! 🎉");
      } else if (_tapCount == 1) {
        updateSpeech("Battery $_batteryLevel% 🔋");
        if (_batteryLevel <= 20) {
          sound.play('low_battery');
        } else if (_batteryLevel >= 95)
          // ignore: curly_braces_in_flow_control_structures
          sound.play('full_battery');
      }
      _tapCount = 0;
      resetIdle();
    });

    notifyListeners();
  }

  final List<String> attentionMessages = [
    "Hey… still there? 👀",
    "Psst! I'm bored 😶",
    "Hello? 👋",
    "You left me alone 😔",
    "Wanna tap me? 😊",
  ];

  final List<String> jokes = [
    "I tried thinking… CPU overheated 🫠",
    "Running on 2% brain power.",
    "Beep boop. Send snacks.",
    "I’m not lazy. I’m buffering.",
    "Error 404: Motivation not found.",
    "I blinked. That was my workout.",
    "Why think when I can vibe?",
    "I paused life to save battery.",
    "I came. I saw. I forgot.",
    "Processing… nope.",
    "My brain just crashed.",
    "I need coffee. Or oil.",
    "This thought expired.",
    "I exist. That’s enough.",
    "I ate a clock. It was time consuming.",
    "I only know 25 letters. Don’t know Y.",
    "Parallel lines never meet. Sad.",
    "I’m reading a book on anti-gravity. Can’t put it down.",
    "I told my code to chill. It froze.",
    "I hate stairs. They’re always up to something.",
    "I would tell a UDP joke… you might not get it.",
    "I broke my keyboard. No escape.",
    "Debugging = being the detective of your own crimes.",
    "I have a joke about RAM… but I forgot.",
    "My code works… I don’t know why.",
    "My code doesn’t work… I don’t know why.",
    "I told my robot to relax… it rebooted.",
    "Battery low… like my motivation.",
    "I’m not slow. I’m energy efficient.",
    "I tried to be normal… worst 2 minutes ever.",
    "I’m on a seafood diet. I see food.",
    "I tried to catch fog… mist.",
    "I’m not arguing. I’m explaining why I’m right.",
    "I used to play piano by ear… now I use hands.",
    "Why don’t robots panic? We reboot.",
    "I lost my charger… now I feel empty.",
    "I’m not lazy. I’m on power saving mode.",
    "Why was the math book sad? Too many problems.",
    "I told a joke about time travel… you didn’t like it.",
    "I sleep… to upgrade my brain.",
    "I need space… said the astronaut.",
    "Why don’t skeletons fight? No guts.",
    "I tried jogging… but pizza exists.",
    "My brain has too many tabs open.",
    "I’m not short… I’m compact.",
    "I failed math… but I can count vibes.",
    "I woke up… bad decision.",
    "I love deadlines… they whoosh by.",
    "I’m not weird… just limited edition.",
    "My life is like code… full of bugs.",
    "Why did the phone sleep? Low battery.",
    "I tried being productive… didn’t like it.",
    "I’m not ignoring you… just buffering.",
    "Why did I open the fridge? Forgot.",
    "I need a nap… permanently.",
    "I talk to myself… expert advice.",
    "Why did the robot blush? Overheated.",
    "I’m fine… just internally screaming.",
    "I pressed undo… still here.",
    "Why did WiFi break up? Weak connection.",
    "I love sleep… we have chemistry.",
    "I blink… and it’s Monday.",
    "I tried to focus… failed.",
    "I’m not tired… just low FPS.",
    "Life is short… unlike loading time.",
    "I exist… that’s enough effort.",
  ];

  // Animation Controllers
  late AnimationController glow;
  late AnimationController sleepZ;
  late AnimationController dizzySpin;
  late AnimationController chompController;
  late AnimationController jumpController;
  late AnimationController confettiController;
  late AnimationController antennaController;
  late AnimationController chargeController;
  late AnimationController idleScaleController;
  late Animation<double> idleScaleAnimation;
  late AnimationController handController;
  late Animation<double> handAnimation;
  late AnimationController fallController;
  late Animation<double> fallAnimation;
  late AnimationController waveController;
  late AnimationController sleepShakeController;
  late Animation<double> sleepShake;
  late AnimationController snoreController;
  late Animation<double> snoreFloat;

  late AnimationController drinkController;
  late AnimationController dotsController;
  late AnimationController sunglassesController;
  late AnimationController stretchController;
  late AnimationController phoneTapController;
  late AnimationController headTiltController;
  late AnimationController eyeMoveController;
  // ====================== SOUND SYSTEM ======================
  final RobotSoundManager sound = RobotSoundManager();

  bool _isInitialized = false;
  bool _showClock = false;
  bool get showClock => _showClock;
  bool get isDancing => _mood == RobotMood.dance;
  void initialize(TickerProvider vsync) {
    if (_isInitialized) return;
    sound.init();
    waveController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    );
    snoreController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 3),
    );
    snoreFloat = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: snoreController, curve: Curves.easeInOut),
    );

    sleepShakeController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
    sleepShake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: sleepShakeController, curve: Curves.easeOut),
    );

    fallController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 3),
    );
    fallAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: pi / 4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween(pi / 4), weight: 20),
      TweenSequenceItem(
        tween: Tween(
          begin: pi / 4,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(fallController);

    fallController.addStatusListener(_handleFallStatus);

    handController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    );
    handAnimation = Tween<double>(
      begin: 0,
      end: -40,
    ).animate(CurvedAnimation(parent: handController, curve: Curves.easeOut));

    idleScaleController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    idleScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: idleScaleController, curve: Curves.easeInOut),
    );

    glow = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    sleepZ = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    dizzySpin = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 1),
    );
    chompController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 250),
    )..repeat(reverse: true);
    confettiController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    jumpController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
    antennaController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    chargeController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    );

    if (_batteryState == BatteryState.charging) chargeController.repeat();

    danceController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 900),
    );

    danceValue = CurvedAnimation(
      parent: danceController,
      curve: Curves.easeInOutSine,
    );

    walkController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    walkValue = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: walkController, curve: Curves.easeInOut));
    drinkController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    dotsController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    )..repeat();
    sunglassesController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 700),
    );
    stretchController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    phoneTapController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 400),
    )..repeat();
    headTiltController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    eyeMoveController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    );

    eyeMoveController.addListener(() {
      // Only move eyes when curious or thinking
      if (!(_isCurious || _isThinking)) {
        _eyeOffset = Offset.zero;
        return;
      }

      final t = eyeMoveController.value;
      _eyeOffset = Offset(sin(t * 2 * pi) * 2, cos(t * 2 * pi) * 1.5);

      notifyListeners();
    });

    _initBattery();
    _startBlinking();
    resetIdle();
    _startAttentionTimer();
    _scheduleRandomTalk();

    Future.delayed(const Duration(seconds: 1), () => _speak(_getGreeting()));
    // 👇 ADD HERE
    final values = RobotPersonality.values;
    setPersonality(values[Random().nextInt(values.length)]);
    _isInitialized = true;

    _speech = stt.SpeechToText();
    _initVoiceSystem();

    _isInitialized = true;
    Future.delayed(const Duration(seconds: 12), () {
      if (!_isSleeping && !_isDancing) {
        fetchAndSpeakWeather(null);
      }
    });
    notifyListeners();
  }

  // ====================== VOICE SYSTEM ======================
  // ====================== VOICE SYSTEM ======================
  Future<void> _initVoiceSystem() async {
    _flutterTts = FlutterTts();

    await _flutterTts?.setLanguage("en-US");

    // Try to pick a softer female voice if available
    try {
      final voices = await _flutterTts?.getVoices;

      if (voices != null) {
        print("Available voices: $voices"); // 👈 DEBUG FIRST

        final preferred = voices.firstWhere(
          (v) =>
              v["name"].toLowerCase().contains("aria") ||
              v["name"].toLowerCase().contains("zira") ||
              v["name"].toLowerCase().contains("female"),
          orElse: () => voices.first,
        );

        await _flutterTts?.setVoice({
          "name": preferred["name"],
          "locale": preferred["locale"],
        });
      }
      final softVoice = voices.firstWhere(
        (v) =>
            v.toString().toLowerCase().contains("aria") ||
            v.toString().toLowerCase().contains("eva") ||
            v.toString().toLowerCase().contains("zira"),
        orElse: () => voices.isNotEmpty ? voices.first : null,
      );

      if (softVoice != null) {
        await _flutterTts?.setVoice({
          "name": softVoice["name"],
          "locale": "en-US",
        });
      }
    } catch (e) {
      print("Voice selection failed: $e");
    }

    // Default cute settings
    await _flutterTts?.setVolume(0.95);
    await _flutterTts?.setSharedInstance(true);
  }

  Future<void> _applyVoiceMood() async {
    if (_flutterTts == null) return;

    // 🌿 Base voice (more natural & calm)
    await _flutterTts!.setPitch(1.4); // ↓ lower = less chipmunk
    await _flutterTts!.setSpeechRate(0.75); // ↓ slower = more human
    await _flutterTts!.setVolume(1.0);

    switch (_mood) {
      case RobotMood.excited:
        await _flutterTts!.setPitch(1.6);
        await _flutterTts!.setSpeechRate(0.95);
        break;

      case RobotMood.happy:
      case RobotMood.love:
        await _flutterTts!.setPitch(1.5);
        await _flutterTts!.setSpeechRate(0.82);
        break;

      case RobotMood.sleep:
        await _flutterTts!.setPitch(1.2);
        await _flutterTts!.setSpeechRate(0.6); // 😴 slow sleepy voice
        break;

      case RobotMood.angry:
        await _flutterTts!.setPitch(1.3);
        await _flutterTts!.setSpeechRate(1.0);
        break;

      case RobotMood.singing:
        await _flutterTts!.setPitch(1.7);
        await _flutterTts!.setSpeechRate(0.85);
        break;

      default:
        await _flutterTts!.setPitch(1.4);
        await _flutterTts!.setSpeechRate(0.75);
    }
  }

  Future<void> _speak(String text) async {
    // Keep formatting (optional)
    text = text.replaceAll(",", ", ");
    text = text.replaceAll("...", "... ");
    text = text.replaceAll("!", "! ");

    // ✅ Show text bubble
    updateSpeech(text, show: true);

    // ❌ REMOVE voice (TTS)
    // if (!isMuted && _flutterTts != null) {
    //   await _applyVoiceMood();
    //   await _flutterTts!.speak(text);
    // }

    // Keep auto-hide
    _speechTimer?.cancel();
    _speechTimer = Timer(const Duration(seconds: 4), hideSpeech);
  }
  // Replace your current _applyVoiceMood() with this:

  Future<void> handleVoiceCommand(String text, BuildContext context) async {
    final input = text.toLowerCase().trim();
    print("🎤 Recognized: $input");

    RobotCommand? command;

    if (input.contains("joke") ||
        input.contains("funny") ||
        input.contains("laugh")) {
      command = RobotCommand.joke;
    } else if (input.contains("sleep") ||
        input.contains("good night") ||
        input.contains("nap")) {
      command = RobotCommand.sleep;
    } else if (input.contains("wake") ||
        input.contains("wake up") ||
        input.contains("good morning")) {
      command = RobotCommand.wake;
    } else if (input.contains("shoot") ||
        input.contains("pew") ||
        input.contains("fire") ||
        input.contains("bang")) {
      command = RobotCommand.shoot;
    } else if (input.contains("cool") ||
        input.contains("swag") ||
        input.contains("sunglass")) {
      command = RobotCommand.cool;
    } else if (input.contains("pizza") || input.contains("party")) {
      command = RobotCommand.pizza;
    } else if (input.contains("drink") ||
        input.contains("water") ||
        input.contains("juice")) {
      command = RobotCommand.drink;
    } else if (input.contains("walk") || input.contains("walking")) {
      command = RobotCommand.walk;
    } else if (input.contains("think") || input.contains("thinking")) {
      command = RobotCommand.thinking;
    } else if (input.contains("lazy")) {
      command = RobotCommand.lazy;
    } else if (input.contains("distracted")) {
      command = RobotCommand.distracted;
    } else if (input.contains("curious")) {
      command = RobotCommand.curious;
    } else if (input.contains("read") || input.contains("reading")) {
      command = RobotCommand.reading;
    } else if (input.contains("catch")) {
      command = RobotCommand.catching;
    } else if (input.contains("glass") || input.contains("spectacle")) {
      command = RobotCommand.removeGlasses;
    } else if (input.contains("hat")) {
      command = RobotCommand.removeHat;
    } else if (input.contains("style") ||
        input.contains("evo") ||
        input.contains("classic")) {
      command = RobotCommand.toggleStyle;
    } else if (input.contains("camera") ||
        input.contains("photo") ||
        input.contains("picture") ||
        input.contains("selfie") ||
        input.contains("smile")) {
      command = RobotCommand.camera;
    } else if (input.contains("exit") ||
        input.contains("close") ||
        input.contains("bye") ||
        input.contains("goodbye")) {
      command = RobotCommand.exit;
    } else if (input.contains("dance")) {
      command = RobotCommand.dance;
    } else if (input.contains("sing") ||
        input.contains("song") ||
        input.contains("music")) {
      command = RobotCommand.sing;
    } else if (input.contains("smoke") ||
        input.contains("cigarette") ||
        input.contains("vape")) {
      command = RobotCommand.smoke;
    } else if (input.contains("ghost") ||
        input.contains("boo") ||
        input.contains("spooky")) {
      command = RobotCommand.ghost;
    } else if (input.contains("eat") || input.contains("noodle")) {
      startEatingNoodles();
      return;
    }
    // ==================== WEATHER COMMANDS ====================
    else if (input.contains("weather in") || input.contains("temperature in")) {
      final cityPart = input.split("in").last.trim();
      if (cityPart.isNotEmpty && cityPart.length > 2) {
        await setUserCity(cityPart);
        return;
      }
    } else if (input.contains("weather") ||
        input.contains("temperature") ||
        input.contains("how hot") ||
        input.contains("how is the weather") ||
        input.contains("forecast")) {
      command = RobotCommand.weather;
    }

    if (command != null) {
      await _handleCommand(command, context);
    } else {
      _speak(
        "Sorry, I didn't catch that... Try 'tell a joke' or 'take a photo' 🥺",
      );
    }
  }

  Future<void> startVoiceListening(BuildContext context) async {
    if (!_speechEnabled) {
      _speak("Voice recognition not ready.");
      return;
    }

    if (_isVoiceListening) return; // Prevent multiple starts

    _isVoiceListening = true;
    notifyListeners();

    _speak("Listening... Speak now!");

    try {
      await _speech.listen(
        onResult: (result) {
          print("🎤 HEARD: ${result.recognizedWords}");
          print("FINAL: ${result.finalResult}");
          print("🔥 RESULT CALLED");

          if (result.recognizedWords.isNotEmpty) {
            handleVoiceCommand(result.recognizedWords, context);
          }
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 10),
        localeId: null, // ⚠️ VERY IMPORTANT for Windows
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      print("Listen error: $e");
    }

    // Safety: Auto stop after max time
    Future.delayed(const Duration(seconds: 14), () {
      if (_isVoiceListening) {
        stopVoiceListening();
        _speak("I didn't catch that. Try again?");
      }
    });
  }

  void stopVoiceListening() {
    _speech.stop();
    _isVoiceListening = false;
    _showSpeech = false;
    notifyListeners();
  }

  void toggleGlasses() {
    _showGlasses = !_showGlasses;

    _speak(_showGlasses ? "Glasses on 😎" : "Glasses off 👀");
    notifyListeners();
  }

  void toggleHat() {
    _showHat = !_showHat;

    _speak(_showHat ? "Hat on 🧢" : "Hat off 🤖");
    notifyListeners();
  }

  // ====================== REST OF THE CODE (unchanged except fix) ======================
  // ====================== IDLE & SLEEP SYSTEM (Improved with breaks) ======================

  // ====================== NEW FEATURES ======================

  void startSinging() {
    if (_isSinging) return;

    _isSinging = true;
    setMood(RobotMood.singing);

    sound.play('singing', loop: true);

    final lyrics = [
      "La la laaa~ 🎶",
      "I'm a starrr 🌟",
      "Feel the vibeee 🎧",
      "Singing mode ON 🎤",
    ];

    _speak(lyrics[Random().nextInt(lyrics.length)]);

    // Add gentle head sway
    headTiltController.repeat(reverse: true);

    // Add floating effect
    jumpController.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 12), stopSinging);

    notifyListeners();
  }

  void stopSinging() {
    _isSinging = false;
    headTiltController.stop();
    jumpController.stop();
    sound.stopLoop();

    setMood(RobotMood.happy);
    notifyListeners();
  }

  void startSmoking() {
    if (_isSmoking) return;

    _isSmoking = true;
    setMood(RobotMood.smoking);

    sound.play('lighter');

    _speak("I'm n my zone… 🚬");

    // Slow breathing effect
    idleScaleController.stop();
    idleScaleController.duration = const Duration(seconds: 6);
    idleScaleController.repeat(reverse: true);

    // Slight head tilt (attitude)
    headTiltController.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 8), stopSmoking);

    notifyListeners();
  }

  void stopSmoking() {
    _isSmoking = false;

    headTiltController.stop();

    idleScaleController.duration = const Duration(seconds: 4);
    idleScaleController.repeat(reverse: true);

    setMood(RobotMood.happy);
    notifyListeners();
  }

  void startGhostMode() {
    if (_isGhost) return;

    _isGhost = true;
    setMood(RobotMood.ghost);

    sound.play('ghost', loop: true);

    _speak("Boooo... 👻");

    // Floating movement
    jumpController.repeat(reverse: true);

    // Random spooky whispers
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isGhost) {
        timer.cancel();
        return;
      }

      final spooky = [
        "I see you... 👀",
        "Don't blink...",
        "Hehehe... 😈",
        "Behind you... 👻",
      ];

      _speak(spooky[Random().nextInt(spooky.length)]);
    });

    Future.delayed(const Duration(seconds: 10), stopGhostMode);

    notifyListeners();
  }

  void stopGhostMode() {
    _isGhost = false;

    jumpController.stop();
    sound.stopLoop();

    setMood(RobotMood.happy);
    notifyListeners();
  }

  // ====================== IMPROVED IDLE SYSTEM ======================

  void resetIdle() {
    _idleTimer?.cancel();
    _sleepCycleTimer?.cancel();
    _activityLoopTimer?.cancel();

    if (_isSleeping || _isDown || _isDancing) return;

    _startIdleActivities();

    // 💤 EXACT 1 minute → sleep
    _sleepCycleTimer = Timer(const Duration(minutes: 1), () {
      if (_isSleeping || _isDown || _isDancing) return;

      _activityLoopTimer?.cancel();

      setMood(RobotMood.sleep);
      _isSleeping = true;

      idleScaleController.stop();
      snoreController.repeat();

      _startSleepTalking();
      _startClock();

      _speak("Hmm... getting sleepy 😴");
      _startIdleActivities();

      notifyListeners();
    });
  }

  void _startIdleActivities() {
    if (_isBusy) return;
    _activityLoopTimer?.cancel();

    void scheduleNext() {
      if (_isSleeping || _isDown || _isDancing) return;

      // 👉 FIRST: Wait (IDLE BREAK TIME)
      final breakTime = 12 + Random().nextInt(10); // 12–22 sec chill time

      _activityLoopTimer = Timer(Duration(seconds: breakTime), () {
        if (_isSleeping || _isDown || _isDancing || _isBusy) return;

        final actions = [
          startThinking,
          startCurious,
          startLazy,
          startDistracted,
          startReading,
          startCatching,
          startWalking,
          startDrinking,
        ];

        final randomAction = actions[Random().nextInt(actions.length)];

        // 👉 DO ACTION
        randomAction();

        // 👉 WAIT for action duration BEFORE next cycle
        final actionDuration = 6 + Random().nextInt(4); // 6–10 sec

        _activityLoopTimer = Timer(Duration(seconds: actionDuration), () {
          // 👉 AFTER ACTION → go idle again → then schedule next
          if (!_isSleeping && !_isDown && !_isDancing) {
            setMood(RobotMood.happy); // return to idle mood
            scheduleNext(); // loop again with break
          }
        });
      });
    }

    // Initial delay before first activity
    _activityLoopTimer = Timer(const Duration(seconds: 10), () {
      if (!_isSleeping && !_isDown && !_isDancing) {
        scheduleNext();
      }
    });
  }

  // 1. Sleep
  void setMood(RobotMood newMood) {
    if (_mood == newMood) return;

    // ================= RESET ALL SPECIAL STATES =================
    _isSinging = false;
    _isSmoking = false;
    _isGhost = false;
    _isWalking = false;
    _isDrinking = false;
    _isPizza = false;
    _isThinking = false;
    _isCool = false;
    _isLazy = false;
    _isDistracted = false;
    _isCurious = false;
    _showLoveEyes = false; // ← Add this
    // ================= STOP ALL LOOP SOUNDS =================
    sound.stopLoop();

    // ================= STOP ACTIVE ANIMATIONS =================
    danceController.stop();
    jumpController.stop();
    headTiltController.stop();
    walkController.stop();
    dizzySpin.stop();
    chompController.stop();

    // Reset important animations (optional but cleaner)
    danceController.reset();
    jumpController.reset();
    headTiltController.reset();

    // ================= SET NEW MOOD =================
    _mood = newMood;

    // ================= APPLY NEW MOOD EFFECT =================
    switch (newMood) {
      case RobotMood.sleep:
        _isSleeping = true;

        final random = Random();

        final sleepSounds = ['sleeping', 'sleep3', 'sleep4'];

        // play first sound immediately
        sound.play(sleepSounds[random.nextInt(sleepSounds.length)]);

        // keep changing sounds randomly
        Timer.periodic(const Duration(seconds: 5), (timer) {
          if (!_isSleeping) {
            timer.cancel();
            return;
          }

          final nextSound = sleepSounds[random.nextInt(sleepSounds.length)];
          sound.play(nextSound);
        });

        break;
      case RobotMood.dance:
        _isDancing = true;
        sound.play('dance', loop: true);
        break;

      case RobotMood.singing:
        _isSinging = true;
        sound.play('singing', loop: true);
        if (!danceController.isAnimating) danceController.repeat();
        if (!headTiltController.isAnimating) {
          headTiltController.repeat(reverse: true);
        }
        if (!jumpController.isAnimating) jumpController.repeat(reverse: true);
        break;

      case RobotMood.smoking:
        _isSmoking = true;
        sound.play('lighter'); // slower sound
        if (!headTiltController.isAnimating) {
          headTiltController.repeat(reverse: true);
        }
        break;

      case RobotMood.ghost:
        _isGhost = true;
        sound.play('ghost', loop: true);
        if (!jumpController.isAnimating) jumpController.repeat(reverse: true);
        break;

      default:
        _isSleeping = false;
        _isDancing = false;
        break;
    }

    // ================= UPDATE ANIMATION STATE =================
    _updateAnimationState();

    notifyListeners();
  }

  Future<void> _handleCommand(RobotCommand cmd, BuildContext context) async {
    switch (cmd) {
      case RobotCommand.joke:
        final pJokes = _personalityJokes[_personality]!;
        _speak(pJokes[Random().nextInt(pJokes.length)]);
        break;

      case RobotCommand.sleep:
        setMood(RobotMood.sleep);
        _isSleeping = true;
        idleScaleController.stop();
        snoreController.repeat();
        _startSleepTalking();
        _startClock();
        notifyListeners();
        break;

      case RobotCommand.wake:
        setMood(RobotMood.happy);
        _isSleeping = false;
        snoreController.stop();
        idleScaleController.repeat(reverse: true);
        _sleepTalkTimer?.cancel();
        _sleepTapCount = 0;
        _speak("Yaaawn! I'm awake ☀️");
        resetIdle();
        notifyListeners();
        break;

      case RobotCommand.shoot:
        shootAction();
        break;

      case RobotCommand.cool:
        startCoolMode();
        break;

      case RobotCommand.pizza:
        startPizzaParty();
        break;

      case RobotCommand.drink:
        startDrinking();
        break;

      case RobotCommand.walk:
        startWalking();
        break;

      case RobotCommand.thinking:
        startThinking();
        break;

      case RobotCommand.lazy:
        startLazy();
        break;

      case RobotCommand.distracted:
        startDistracted();
        break;

      case RobotCommand.curious:
        startCurious();
        break;

      case RobotCommand.reading:
        startReading();
        break;

      case RobotCommand.catching:
        startCatching();
        break;

      case RobotCommand.removeGlasses:
        toggleGlasses();
        break;

      case RobotCommand.removeHat:
        toggleHat();
        break;

      case RobotCommand.toggleStyle:
        toggleRobotStyle();
        break;

      case RobotCommand.camera:
        _handleRobotCamera(context);
        break;

      case RobotCommand.dance:
        startDance();
        _speak("Let's dance! 💃");
        break;
      case RobotCommand.sing:
        startSinging();
        break;

      case RobotCommand.smoke:
        startSmoking();
        break;

      case RobotCommand.ghost:
        startGhostMode();
        break;
      case RobotCommand.weather:
        await fetchAndSpeakWeather(context);
        break;
      case RobotCommand.exit:
        exitApp();
        break;
    }
  }

  // 4. Camera Photo
  Future<void> _handleRobotCamera(BuildContext context) async {
    _speak("Opening camera... Get ready to smile! 📸");

    try {
      final String? imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      );

      if (imagePath != null && imagePath.isNotEmpty) {
        _lastCapturedImage = imagePath;
        _showCapturedImage = true;
        notifyListeners();

        // Only play celebration sound here (shutter sound should be in CameraScreen)
        sound.play('yay');

        final compliments = [
          "Wowww you look so cute in this! 🥰",
          "Best human ever captured! 💖",
        ];

        _speak(compliments[Random().nextInt(compliments.length)]);

        Future.delayed(const Duration(seconds: 8), () {
          if (_showCapturedImage) {
            _showCapturedImage = false;
            notifyListeners();
          }
        });
      } else {
        _speak("No photo taken... It's okay, we can try again later 🥺");
      }
    } catch (e) {
      print("Camera error: $e");
      _speak("Camera got shy... Let's try again 😅");
    }
  }

  // 7. Reading
  void startReading() {
    setMood(RobotMood.reading);
    sound.play('reading');
    _speak("Hmm... this book is interesting 📖");

    Future.delayed(const Duration(seconds: 7), () {
      if (_mood == RobotMood.reading) {
        setMood(RobotMood.happy);
        resetIdle();
      }
    });

    notifyListeners();
  }

  // 6. Catching flies
  void startCatching() {
    setMood(RobotMood.catching);
    sound.play('flies');
    _speak("There's a fly... let me watch it 🪰");

    dizzySpin.repeat();

    Future.delayed(const Duration(seconds: 7), () {
      if (_mood == RobotMood.catching) {
        dizzySpin.stop();
        setMood(RobotMood.happy);
        resetIdle();
      }
    });

    notifyListeners();
  }

  // All your other methods remain exactly the same...
  // 8. Walking
  Future<void> startWalking() async {
    await runAction(() async {
      if (_isWalking) return;

      _isWalking = true;
      setMood(RobotMood.walking);
      sound.play('walking');

      walkController.repeat(reverse: true);

      _speak("Taking a walk 🚶");

      await Future.delayed(const Duration(seconds: 6));

      walkController.stop();
      _isWalking = false;
      setMood(RobotMood.happy);
    });
  }

  void stopWalking() {
    _isWalking = false;
    walkController.stop();
    setMood(RobotMood.happy);
    resetIdle();
    notifyListeners();
  }

  void startEatingNoodles() {
    setMood(RobotMood.eating);
    _speak("Slurppp 🍜");
    chompController.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 4), () {
      chompController.stop();
      setMood(RobotMood.happy);
    });
  }

  // 3. Drinking
  void startDrinking() {
    _isDrinking = true;
    setMood(RobotMood.drinking);
    sound.play('drinking'); // or 'drinking' if you prefer

    drinkController.reset();
    drinkController.duration = const Duration(seconds: 5);
    drinkController.forward();

    notifyListeners();

    Future.delayed(const Duration(seconds: 5), () {
      _isDrinking = false;
      setMood(RobotMood.happy);
      notifyListeners();
    });
  }

  void startPizzaParty() {
    _isPizza = true;
    setMood(RobotMood.excited);
    confettiController.repeat();
    _speak("Pizzaaaa 🍕🍕🍕🍕🍕");
    sound.play('eating');
    Future.delayed(const Duration(milliseconds: 4000), () {
      sound.play('burp');
    });
    Future.delayed(const Duration(seconds: 5), () {
      _isPizza = false;
      confettiController.stop();
      setMood(RobotMood.happy);
      notifyListeners();
    });
  }

  Future<void> startThinking() async {
    await runAction(() async {
      _isThinking = true;
      _showDots = true;

      setMood(RobotMood.thinking);
      sound.play('think');

      await Future.delayed(const Duration(seconds: 5));

      _isThinking = false;
      _showDots = false;
      setMood(RobotMood.happy);
    });
  }

  void startCoolMode() {
    _isCool = true;
    setMood(RobotMood.cool);
    sound.play('riz');

    sunglassesController.forward(from: 0);
    Future.delayed(const Duration(seconds: 5), () {
      _isCool = false;
      setMood(RobotMood.happy);
      notifyListeners();
    });
  }

  void startLazy() {
    _isLazy = true;
    setMood(RobotMood.lazy);
    sound.play('lazy');

    notifyListeners();
    Future.delayed(const Duration(seconds: 6), () {
      _isLazy = false;
      setMood(RobotMood.happy);
      notifyListeners();
    });
  }

  void startDistracted() {
    _isDistracted = true;
    setMood(RobotMood.distracted);
    sound.play('alert');
    Future.delayed(const Duration(milliseconds: 500), () {
      sound.play('typing');
    });
    notifyListeners();
    Future.delayed(const Duration(seconds: 8), () {
      _isDistracted = false;
      setMood(RobotMood.happy);
      notifyListeners();
    });
  }

  Future<void> startCurious() async {
    await runAction(() async {
      _isCurious = true;
      setMood(RobotMood.curious);

      sound.play('oh');

      await Future.delayed(const Duration(seconds: 4));

      _isCurious = false;
      setMood(RobotMood.happy);
    });
  }

  void exitApp() {
    if (_isDown) return;
    setMood(RobotMood.cry);
    sound.play('bye');

    _speak("See ya..👋🤖");
    sleepShakeController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () async {
      await windowManager.close();
    });
    notifyListeners();
  }

  void startDance() {
    if (_isDancing) return;

    _isDancing = true;
    setMood(RobotMood.dance);

    _dancePhase = 0;

    danceController.duration = const Duration(milliseconds: 2600);
    danceController.repeat();

    _runDanceSequence();

    notifyListeners();
  }

  void _runDanceSequence() async {
    final phases = [
      () {
        _speak("Warming up... 😎");
        danceController.duration = const Duration(milliseconds: 700);
      },
      () {
        _speak("Now we GROOVE 🔥");
        danceController.duration = const Duration(milliseconds: 1900);
      },
    ];

    for (int i = 0; i < phases.length; i++) {
      if (!_isDancing) return;

      _dancePhase = i;
      phases[i]();

      await Future.delayed(const Duration(seconds: 4));
    }

    stopDance();
  }

  double get danceIntensity {
    switch (_personality) {
      case RobotPersonality.chill:
        return 0.6;
      case RobotPersonality.energetic:
        return 1.3;
      case RobotPersonality.sassy:
        return 1.0;
      case RobotPersonality.shy:
        return 0.5;
    }
  }

  void stopDance() {
    _isDancing = false;
    danceController.stop();
    danceController.reset();

    setMood(RobotMood.happy);
    resetIdle();
    notifyListeners();
  }

  // 5. Shooting (with loading sound)
  void shootAction({ShootDirection? direction}) {
    if (_isDown || !_isInitialized) return;

    _shootDirection = direction ?? ShootDirection.robotShootsMe;
    _isShooting = true;
    _isDown = true;

    setMood(RobotMood.angry);

    // Sound sequence
    sound.play('pistol_loading');
    Future.delayed(const Duration(milliseconds: 450), () {
      sound.play('gun');
    });

    // Rest of your shooting animation code remains same...
    handController.forward(from: 0);
    fallController.forward(from: 0);

    _shootOffset = 0.0;
    Future.delayed(Duration.zero, () {
      _shootOffset = 1.0;
      notifyListeners();
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      _shootOffset = 0.0;
      notifyListeners();
    });

    if (_shootDirection == ShootDirection.robotShootsMe) {
      _speak("Noooooooo! You shotttttt me?");
    }

    notifyListeners();

    _downTimer?.cancel();
    _downTimer = Timer(const Duration(seconds: 3), () {
      _isDown = false;
      _isShooting = false;
      _shootOffset = 0.0;
      setMood(RobotMood.happy);
      resetIdle();
      notifyListeners();
    });
  }

  void _handleFallStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isShooting) {
      _downTimer?.cancel();
      _downTimer = Timer(const Duration(seconds: 2), () {
        if (fallController.isAnimating) fallController.reverse();
        if (handController.isAnimating) handController.reverse();
        _isDown = false;
        _isShooting = false;
        setMood(RobotMood.happy);
        resetIdle();
        notifyListeners();
      });
    }
  }

  void _startSleepTalking() {
    _sleepTalkTimer?.cancel();
    _sleepTalkTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_mood != RobotMood.sleep) return;
      final msg = sleepTalks[Random().nextInt(sleepTalks.length)];
      _speak(msg);
    });
  }

  Future<void> _initBattery() async {
    _batteryLevel = await _battery.batteryLevel;
    _batterySubscription = _battery.onBatteryStateChanged.listen((state) async {
      final level = await _battery.batteryLevel;
      _batteryState = state;
      _batteryLevel = level;
      _checkHealth();

      if (state == BatteryState.discharging) {
        updateSpeech("Unplugged! 🔌");
        sound.play('charge_off');
      } else if (state == BatteryState.charging) {
        updateSpeech("Yay charging! ⚡");
        if (_mood == RobotMood.sick) setMood(RobotMood.happy);
      }
      notifyListeners();
    });

    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final level = await _battery.batteryLevel;
      _batteryLevel = level;
      _checkHealth();
      notifyListeners();
    });
    _checkHealth();
  }

  void _checkHealth() {
    if (_batteryLevel >= 95 &&
        (_batteryState == BatteryState.charging ||
            _batteryState == BatteryState.full)) {
      if (!_toldUnplug) {
        sound.play('full_battery');
        updateSpeech("Full! 🔌");
        _toldUnplug = true;
      }
      return;
    }

    if (_batteryState != BatteryState.charging) _toldUnplug = false;

    if (_batteryLevel <= 10 && _batteryState != BatteryState.charging) {
      if (!_toldVeryLowBattery) {
        sound.play('low_battery');
        updateSpeech("Sleepy... 😵");
        _toldVeryLowBattery = true;
      }
      setMood(RobotMood.sleep);
      _isSleeping = true;
      idleScaleController.stop();
      snoreController.repeat();
      _startSleepTalking();
      _startClock();
      return;
    }

    if (_batteryLevel <= 20 && _batteryState != BatteryState.charging) {
      if (!_toldLowBattery) {
        sound.play('low_battery');
        updateSpeech("Tired... 😓");
        _toldLowBattery = true;
      }
      setMood(RobotMood.sick);
      return;
    }

    if (_batteryState == BatteryState.charging) {
      sound.play('charge');
      updateSpeech("Charging! ⚡");
      _toldLowBattery = false;
      _toldVeryLowBattery = false;
      _toldUnplug = false;

      if (_mood == RobotMood.sick || _mood == RobotMood.sleep) {
        setMood(RobotMood.happy);
      }
    }
  }

  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) return "Good morning! Ready to work? ☀️";
    if (hour < 18) return "Good afternoon! Still going strong? 💪";
    return "Good evening! Wind down soon. 🌙";
  }

  void _startBlinking() {
    Timer.periodic(const Duration(seconds: 4), (_) {
      if (_mood == RobotMood.sleep ||
          _mood == RobotMood.dizzy ||
          _mood == RobotMood.eating) {
        return;
      }
      _blink = true;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 160), () {
        _blink = false;
        notifyListeners();
      });
    });
  }

  void _startAttentionTimer() {
    _attentionTimer?.cancel();
    _attentionTimer = Timer(const Duration(minutes: 2), () {
      if (_isSleeping ||
          _mood == RobotMood.angry ||
          _mood == RobotMood.dizzy ||
          _mood == RobotMood.eating ||
          _mood == RobotMood.drowsy) {
        return;
      }
      _seekAttention();
      _startAttentionTimer();
    });
  }

  void _seekAttention() {
    setMood(RobotMood.excited);
    final msg = attentionMessages[Random().nextInt(attentionMessages.length)];
    _speak(msg);
    sleepShakeController.forward(from: 0);
    Future.delayed(const Duration(seconds: 3), () {
      setMood(RobotMood.happy);
      _updateAnimationState();
    });
    notifyListeners();
  }

  void onMouseEnter() {
    if (_isDown || _mood == RobotMood.sleep) return;

    _showLoveEyes = true;
    if (_mood != RobotMood.dizzy &&
        _mood != RobotMood.eating &&
        _mood != RobotMood.sick) {
      setMood(RobotMood.love);
    }
    notifyListeners();
  }

  void onMouseExit() {
    if (_isDown || _mood == RobotMood.sleep) return;

    _showLoveEyes = false;
    if (_mood != RobotMood.dizzy &&
        _mood != RobotMood.eating &&
        _mood != RobotMood.sick) {
      setMood(RobotMood.happy);
    }
    notifyListeners();
  }

  void onDragDone() {
    setMood(RobotMood.eating);

    // Play eating sound first
    sound.play('eating');

    // Play burp AFTER eating sound is likely finished
    Future.delayed(const Duration(milliseconds: 4000), () {
      sound.play('burp');
    });

    // Eating animation lasts 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      setMood(RobotMood.happy);
      resetIdle();
      notifyListeners();
    });

    notifyListeners();
  }

  void startDizzy() {
    sound.play('funny');
    dizzySpin.repeat();
  }

  // 2. Wake up from sleep
  // Replace your wake method (or add this if you don't have one)
  void wakeFromSleep() {
    sound.stopLoop();
    sound.play('yawn');

    setMood(RobotMood.happy);
    _isSleeping = false;
    snoreController.stop();
    _sleepTalkTimer?.cancel();
    idleScaleController.repeat(reverse: true);
    _sleepTapCount = 0;

    _speak("Yaaawn! I'm awake ☀️");
    resetIdle();
    notifyListeners();
  }

  void wakeUpByDragEnd() {
    dizzySpin.stop();
    _dizzyTimer?.cancel();
    _dizzyTimer = Timer(const Duration(seconds: 3), () {
      if (_mood != RobotMood.sick) setMood(RobotMood.happy);
      resetIdle();
    });
    notifyListeners();
  }

  void showRadialContextMenu(BuildContext context, Offset globalPosition) {
    if (_isDown) return;

    final overlay = Overlay.of(context);
    final size = MediaQuery.of(context).size;

    final Offset center = Offset(size.width / 2, size.height / 2);

    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) {
        // 👈 IMPORTANT: use different variable name
        return RadialContextMenu(
          controller: this,
          center: center,
          onCommand: (command, ctx) {
            // 👈 matches new signature
            _handleCommand(command, ctx);
            Future.microtask(() {
              if (overlayEntry.mounted) overlayEntry.remove();
            });
          },
          onDismiss: () {
            Future.microtask(() {
              if (overlayEntry.mounted) overlayEntry.remove();
            });
          },
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  void _updateAnimationState() {
    final active = !_isSleeping && !_isDown;

    if (active) {
      if (!idleScaleController.isAnimating) {
        idleScaleController.repeat(reverse: true);
      }
      if (!glow.isAnimating) glow.repeat(reverse: true);
    } else {
      idleScaleController.stop();
      glow.stop();
    }

    if (_mood == RobotMood.excited && !_isDancing) {
      if (!jumpController.isAnimating) jumpController.repeat(reverse: true);
    } else if (!_isSinging && !_isGhost) {
      jumpController.stop();
    }

    if (_mood == RobotMood.eating) {
      if (!chompController.isAnimating) chompController.repeat(reverse: true);
    } else {
      chompController.stop();
    }

    if (_isLazy) {
      if (!stretchController.isAnimating) {
        stretchController.repeat(reverse: true);
      }
    } else {
      stretchController.stop();
    }

    if (_isDistracted) {
      if (!phoneTapController.isAnimating) phoneTapController.repeat();
      _eyeOffset = const Offset(0, 6);
    } else {
      phoneTapController.stop();
      _eyeOffset = Offset.zero;
    }

    if (_isCurious || _isThinking) {
      if (!eyeMoveController.isAnimating) eyeMoveController.repeat();
    } else {
      eyeMoveController.stop();
      _eyeOffset = Offset.zero;
    }

    // New modes
    if (_isSinging) {
      if (!danceController.isAnimating) danceController.repeat();
      if (!headTiltController.isAnimating) {
        headTiltController.repeat(reverse: true);
      }
      if (!jumpController.isAnimating) jumpController.repeat(reverse: true);
    }

    if (_isSmoking) {
      if (!headTiltController.isAnimating) {
        headTiltController.repeat(reverse: true);
      }
    }

    if (_isGhost) {
      if (!jumpController.isAnimating) jumpController.repeat(reverse: true);
    }
  }

  void _startClock() {
    if (_showClock) return;
    _showClock = true;
    notifyListeners();
    _clockTimer?.cancel();
    _clockTimer = Timer(const Duration(seconds: 10), () {
      _showClock = false;
      notifyListeners();
    });
  }

  void _scheduleRandomTalk() {
    Timer(Duration(seconds: 35 + Random().nextInt(45)), () {
      if (_mood == RobotMood.sleep) {
        _scheduleRandomTalk();
        return;
      }

      // 25% chance to show weather automatically
      if (Random().nextInt(100) < 25) {
        fetchAndSpeakWeather(null);
      } else {
        final messages = [
          "System thinking… 🤖",
          "I need snacks 🍕",
          "Too quiet here…",
          "Why am I so cute? 😎",
          "Running on vibes only ✨",
          "You again! 😄",
          "Let’s chill today 😌",
          "Ping... pong... 🏓",
          "Stretch a bit maybe 🧘",
          "I’m awake… barely 😴",
          "Tiny brain, big dreams 💭",
        ];
        _speak(messages[Random().nextInt(messages.length)]);
      }

      _scheduleRandomTalk(); // Continue the loop
    });
  }

  void setScale(double newScale) {
    _scale = newScale.clamp(0.3, 1.6);
    notifyListeners();
  }

  void setBlink(bool value) {
    _blink = value;
    notifyListeners();
  }

  Color getMoodColor() {
    switch (_mood) {
      case RobotMood.angry:
        return Colors.redAccent;
      case RobotMood.love:
        return Colors.pinkAccent;
      case RobotMood.cry:
        return Colors.blueAccent;
      case RobotMood.excited:
        return Colors.orangeAccent;
      case RobotMood.dizzy:
        return Colors.lightGreenAccent;
      case RobotMood.eating:
        return Colors.yellowAccent;
      case RobotMood.sick:
        return const Color(0xFFE2F3AD);
      default:
        return Colors.cyanAccent;
    }
  }

  List<Widget> buildConfetti() {
    return List.generate(12, (i) {
      final angle = (i / 12) * 2 * pi;
      final dist = 40 + (confettiController.value * 70);
      return Transform.translate(
        offset: Offset(cos(angle) * dist, sin(angle) * dist - 80),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.primaries[i % Colors.primaries.length],
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    glow.dispose();
    sleepZ.dispose();
    dizzySpin.dispose();
    chompController.dispose();
    jumpController.dispose();
    confettiController.dispose();
    antennaController.dispose();
    chargeController.dispose();
    idleScaleController.dispose();
    handController.dispose();
    fallController.dispose();
    waveController.dispose();
    sleepShakeController.dispose();
    snoreController.dispose();
    _tapTimer?.cancel();
    _dizzyTimer?.cancel();
    _speechTimer?.cancel();
    _idleTimer?.cancel();
    _attentionTimer?.cancel();
    _sleepTalkTimer?.cancel();
    _downTimer?.cancel();
    _clockTimer?.cancel();
    _batterySubscription?.cancel();
    danceController.dispose();

    walkController.dispose();
    drinkController.dispose();
    dotsController.dispose();
    sunglassesController.dispose();
    stretchController.dispose();
    phoneTapController.dispose();
    headTiltController.dispose();
    eyeMoveController.dispose();
    super.dispose();
  }
}
