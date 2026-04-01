import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PixelNeonDroneDashApp());
}

class PixelNeonDroneDashApp extends StatelessWidget {
  const PixelNeonDroneDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Neon Drone Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.pressStart2pTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const Root(),
    );
  }
}

enum ScreenId { menu, game, gameOver }

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  final _prefsFuture = SharedPreferences.getInstance();

  ScreenId _screen = ScreenId.menu;
  int _best = 0;
  int _finalScore = 0;
  bool _removeAds = false;

  InterstitialAd? _interstitial;
  bool _isLoadingInterstitial = false;

  @override
  void initState() {
    super.initState();
    _loadMeta();
    _loadInterstitial();
  }

  Future<void> _loadMeta() async {
    final prefs = await _prefsFuture;
    setState(() {
      _best = prefs.getInt('best') ?? 0;
      _removeAds = prefs.getBool('remove_ads') ?? false;
    });
  }

  Future<void> _saveBest(int score) async {
    final prefs = await _prefsFuture;
    final cur = prefs.getInt('best') ?? 0;
    if (score > cur) {
      await prefs.setInt('best', score);
      _best = score;
    }
  }

  void _loadInterstitial() {
    if (_removeAds) return;
    if (_isLoadingInterstitial) return;
    _isLoadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // тестовый interstitial
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingInterstitial = false;
          _interstitial?.dispose();
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) {
          _isLoadingInterstitial = false;
          _interstitial = null;
        },
      ),
    );
  }

  Future<void> _showInterstitialIfAny() async {
    if (_removeAds) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );

    await ad.show();
  }

  Future<void> _onGameOver(int score) async {
    _finalScore = score;
    await _saveBest(score);
    await _showInterstitialIfAny();
    setState(() => _screen = ScreenId.gameOver);
  }

  Future<void> _purchaseRemoveAds() async {
    final ok = await PlatformBridge.instance.purchaseRemoveAds();
    if (!ok) return;
    final prefs = await _prefsFuture;
    await prefs.setBool('remove_ads', true);
    setState(() => _removeAds = true);
  }

  Future<void> _openLeaderboard() async {
    await PlatformBridge.instance.openLeaderboard();
  }

  Future<void> _shareScore() async {
    await PlatformBridge.instance.shareText(
      'Я набрал $_finalScore в Pixel Neon Drone Dash! Попробуй побить мой рекорд.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _screen.index,
          children: [
            MainMenuScreen(
              best: _best,
              removeAds: _removeAds,
              onPlay: () => setState(() => _screen = ScreenId.game),
              onLeaderboard: _openLeaderboard,
              onBuyRemoveAds: _purchaseRemoveAds,
            ),
            GameScreen(
              onGameOver: _onGameOver,
              onExitToMenu: () => setState(() => _screen = ScreenId.menu),
            ),
            GameOverScreen(
              score: _finalScore,
              best: _best,
              onPlayAgain: () => setState(() => _screen = ScreenId.game),
              onShare: _shareScore,
              onMenu: () => setState(() => _screen = ScreenId.menu),
            ),
          ],
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  final int best;
  final bool removeAds;
  final VoidCallback onPlay;
  final VoidCallback onLeaderboard;
  final VoidCallback onBuyRemoveAds;

  const MainMenuScreen({
    super.key,
    required this.best,
    required this.removeAds,
    required this.onPlay,
    required this.onLeaderboard,
    required this.onBuyRemoveAds,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _BackgroundLayer(),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'PIXEL\nNEON\nDRONE\nDASH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.05,
                      shadows: _neonTextShadows(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _NeonLabel(
                    text: 'Best: ${best.toString().padLeft(3, '0')}',
                    color: Colors.white,
                  ),
                  const SizedBox(height: 18),
                  const _MenuDronePreview(),
                  const SizedBox(height: 18),
                  _BigNeonButton(text: '▶ PLAY', onPressed: onPlay),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SmallNeonButton(text: 'Leaderboard', onPressed: onLeaderboard),
                      const SizedBox(width: 10),
                      _SmallNeonButton(
                        text: removeAds ? 'Ads: OFF' : 'Remove Ads 99₽',
                        onPressed: removeAds ? null : onBuyRemoveAds,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tap = jump + change color',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      shadows: _neonTextShadows(Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GameOverScreen extends StatelessWidget {
  final int score;
  final int best;
  final VoidCallback onPlayAgain;
  final VoidCallback onShare;
  final VoidCallback onMenu;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.best,
    required this.onPlayAgain,
    required this.onShare,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _BackgroundLayer(),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GAME OVER',
                    style: TextStyle(fontSize: 26, shadows: _neonTextShadows(Colors.white)),
                  ),
                  const SizedBox(height: 18),
                  _NeonLabel(
                    text: 'FINAL SCORE: ${score.toString().padLeft(3, '0')}',
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  _NeonLabel(
                    text: 'BEST: ${best.toString().padLeft(3, '0')}',
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 18),
                  _BigNeonButton(text: '🔄 PLAY AGAIN', onPressed: onPlayAgain),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SmallNeonButton(text: '📱 Share Score', onPressed: onShare),
                      const SizedBox(width: 10),
                      _SmallNeonButton(text: 'Menu', onPressed: onMenu),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GameScreen extends StatefulWidget {
  final Future<void> Function(int score) onGameOver;
  final VoidCallback onExitToMenu;

  const GameScreen({super.key, required this.onGameOver, required this.onExitToMenu});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  late GameWorld _world;
  int _score = 0;
  bool _dead = false;
  double _lastUs = 0;

  @override
  void initState() {
    super.initState();
    _world = GameWorld();
    _ticker = AnimationController(vsync: this, duration: const Duration(days: 365))
      ..addListener(_tick)
      ..forward();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _dead) return;
    final us = (_ticker.lastElapsedDuration?.inMicroseconds ?? 0).toDouble();
    final dt = _lastUs == 0 ? (1 / 60) : ((us - _lastUs) / 1e6);
    _lastUs = us;

    final res = _world.update(dt);
    if (res.scored > 0) {
      _score += res.scored;
      _world.applySpeedFromScore(_score);
    }
    if (res.gameOver) {
      _dead = true;
      SystemSound.play(SystemSoundType.alert); // boom
      HapticFeedback.mediumImpact();
      widget.onGameOver(_score);
    }
    setState(() {});
  }

  void _onTap() {
    if (_dead) return;
    _world.onTap();
    SystemSound.play(SystemSoundType.click); // beep
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: Stack(
        children: [
          const _BackgroundLayer(),
          Center(
            child: LayoutBuilder(
              builder: (context, c) {
                const baseW = 360.0;
                const baseH = 640.0;
                final scale = max(1.0, min(c.maxWidth / baseW, c.maxHeight / baseH).floorToDouble());
                return SizedBox(
                  width: baseW * scale,
                  height: baseH * scale,
                  child: CustomPaint(
                    painter: GamePainter(world: _world, score: _score, pixelScale: scale),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NeonLabel(
                  text: 'SCORE: ${_score.toString().padLeft(3, '0')}',
                  color: Colors.white,
                ),
                _SmallNeonButton(
                  text: 'Menu',
                  onPressed: () {
                    _ticker.stop();
                    widget.onExitToMenu();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Игровой мир и сущности.
/// =======================

class GameWorld {
  static const double w = 360;
  static const double h = 640;

  final _rng = Random();

  final player = Player(y: 240, color: 0);
  final List<BarrierPair> barriers = [];
  final List<Spark> sparks = [];

  double gameSpeed = 4.0;
  double _spawnCooldown = 0;

  // звёздная пыль (10 точек)
  final List<Star> stars = List.generate(
    10,
    (i) => Star(x: 20.0 + i * 34.0, y: 40.0 + (i * 59.0) % 520.0, s: 1.0 + (i % 3).toDouble()),
  );

  GameWorld() {
    // стартовые пары
    for (var i = 0; i < 3; i++) {
      barriers.add(_spawnPair(x: w + 120.0 + i * 190));
    }
  }

  void onTap() {
    player.jumpAndShiftColor();
    _spawnSparks();
  }

  void applySpeedFromScore(int score) {
    final bonus = (score ~/ 20) * 0.5;
    gameSpeed = 4.0 + bonus;
    gameSpeed = gameSpeed.clamp(4.0, 8.0);
  }

  UpdateResult update(double dt) {
    final t60 = dt * 60.0;

    // фон: звезды чуть двигаются
    for (final s in stars) {
      s.x -= (0.8 + s.s * 0.2) * t60;
      if (s.x < -4) {
        s.x = w + _rng.nextDouble() * 60;
        s.y = 20 + _rng.nextDouble() * (h - 40);
      }
    }

    player.update(dt);
    if (player.y > h - player.size / 2 || player.y < player.size / 2) {
      return UpdateResult(gameOver: true, scored: 0);
    }

    // барьеры
    int scored = 0;
    for (final b in barriers) {
      b.x -= gameSpeed * t60;

      // скор: за пролет пары (центр пары прошёл x игрока)
      if (!b.scored && b.x + b.width < player.x) {
        b.scored = true;
        scored += 1;
      }

      // коллизия: если касание и цвет не совпал — гейм овер
      if (player.collides(b.topRect) || player.collides(b.bottomRect)) {
        if (player.color != b.color) {
          return UpdateResult(gameOver: true, scored: scored);
        }
      }
    }

    // удаляем ушедшие
    barriers.removeWhere((b) => b.x + b.width < -40);

    // спавн
    _spawnCooldown -= dt;
    final needSpawn = barriers.isEmpty || barriers.last.x < (w - 40);
    if (needSpawn && _spawnCooldown <= 0) {
      final lastX = barriers.isEmpty ? w + 160 : barriers.last.x;
      barriers.add(_spawnPair(x: lastX + 190 + _rng.nextDouble() * 40));
      _spawnCooldown = 0.05;
    }

    // искры
    for (final sp in sparks) {
      sp.update(dt);
    }
    sparks.removeWhere((s) => s.life <= 0);

    return UpdateResult(gameOver: false, scored: scored);
  }

  BarrierPair _spawnPair({required double x}) {
    const gap = 190.0; // шире чем flappy
    const minTop = 90.0;
    const maxTop = h - 90.0 - gap;
    final topH = minTop + _rng.nextDouble() * (maxTop - minTop);
    final color = _rng.nextInt(3);
    return BarrierPair(
      x: x,
      topH: topH,
      gap: gap,
      color: color,
    );
  }

  void _spawnSparks() {
    final c = PlayerColors.colors[player.color];
    for (var i = 0; i < 14; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final spd = 2.5 + _rng.nextDouble() * 4.0;
      sparks.add(
        Spark(
          x: player.x + (cos(a) * 6),
          y: player.y + (sin(a) * 6),
          vx: cos(a) * spd,
          vy: sin(a) * spd,
          life: 0.28 + _rng.nextDouble() * 0.16,
          color: c.glow,
        ),
      );
    }
  }
}

class UpdateResult {
  final bool gameOver;
  final int scored;
  const UpdateResult({required this.gameOver, required this.scored});
}

class Player {
  final double x = 120;
  double y;
  double yVel = 0;
  int color;

  // 48x48 в виртуальных пикселях
  final double size = 48;

  Player({required this.y, required this.color});

  void jumpAndShiftColor() {
    yVel = -14;
    color = (color + 1) % 3;
  }

  void update(double dt) {
    final t60 = dt * 60.0;
    yVel += 0.6 * t60; // гравитация из ТЗ
    y += yVel * t60;
  }

  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: size, height: size);

  bool collides(Rect other) => rect.overlaps(other);
}

class BarrierPair {
  double x;
  final double width = 96; // 96x384 (в сумме), но тут пара по ширине 96
  final double topH;
  final double gap;
  final int color; // 0..2
  bool scored = false;

  BarrierPair({required this.x, required this.topH, required this.gap, required this.color});

  Rect get topRect => Rect.fromLTWH(x, 0, width, topH);
  Rect get bottomRect => Rect.fromLTWH(x, topH + gap, width, GameWorld.h - (topH + gap));
}

class Spark {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  final Color color;

  Spark({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.color});

  void update(double dt) {
    final t60 = dt * 60.0;
    x += vx * t60;
    y += vy * t60;
    vx *= pow(0.88, t60).toDouble();
    vy *= pow(0.88, t60).toDouble();
    life -= dt;
  }
}

class Star {
  double x;
  double y;
  final double s;
  Star({required this.x, required this.y, required this.s});
}

class PlayerColors {
  static const colors = <PlayerColor>[
    PlayerColor(fill: Color(0xFFFF4444), glow: Color(0xFFFF8888)),
    PlayerColor(fill: Color(0xFF4444FF), glow: Color(0xFF8888FF)),
    PlayerColor(fill: Color(0xFF44FF44), glow: Color(0xFF88FF88)),
  ];
}

class PlayerColor {
  final Color fill;
  final Color glow;
  const PlayerColor({required this.fill, required this.glow});
}

/// =======================
/// Рендер (CustomPainter).
/// =======================

class GamePainter extends CustomPainter {
  final GameWorld world;
  final int score;
  final double pixelScale;

  GamePainter({required this.world, required this.score, required this.pixelScale});

  @override
  void paint(Canvas canvas, Size size) {
    // Рисуем в виртуальных координатах 360x640.
    canvas.save();
    canvas.scale(pixelScale, pixelScale);

    _paintGrid(canvas);
    _paintStars(canvas);
    _paintBarriers(canvas);
    _paintSparks(canvas);
    _paintDrone(canvas);

    canvas.restore();
  }

  void _paintGrid(Canvas canvas) {
    const cell = 32.0;
    final p = Paint()
      ..color = const Color(0xFF101018)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double x = 0; x <= GameWorld.w; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, GameWorld.h), p);
    }
    for (double y = 0; y <= GameWorld.h; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(GameWorld.w, y), p);
    }
  }

  void _paintStars(Canvas canvas) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (final s in world.stars) {
      canvas.drawRect(Rect.fromLTWH(s.x, s.y, s.s, s.s), p);
    }
  }

  void _paintBarriers(Canvas canvas) {
    for (final b in world.barriers) {
      final pc = PlayerColors.colors[b.color];
      _pixelGlowRect(canvas, b.topRect, pc.fill, pc.glow);
      _pixelGlowRect(canvas, b.bottomRect, pc.fill, pc.glow);
    }
  }

  void _paintSparks(Canvas canvas) {
    for (final sp in world.sparks) {
      final a = (sp.life / 0.45).clamp(0.0, 1.0);
      final p = Paint()..color = sp.color.withValues(alpha: a);
      canvas.drawRect(Rect.fromLTWH(sp.x, sp.y, 2, 2), p);
    }
  }

  void _paintDrone(Canvas canvas) {
    final c = PlayerColors.colors[world.player.color];
    final r = world.player.rect;

    // glow (пиксельный — делаем несколько слоёв)
    final glow = Paint()
      ..color = c.glow.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(r.inflate(3), glow);

    // тело: квадрат + ободок, чтобы был "неон"
    final body = Paint()..color = c.fill;
    canvas.drawRect(r, body);

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(r.deflate(1), border);

    // "пепе-похожесть": глазки пикселями (дрон-лягушка)
    final eyeW = 6.0;
    final eyeH = 6.0;
    final eyeY = r.top + 12;
    final leftX = r.left + 10;
    final rightX = r.left + 32;
    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final eyePupil = Paint()..color = Colors.black.withValues(alpha: 0.85);
    canvas.drawRect(Rect.fromLTWH(leftX, eyeY, eyeW, eyeH), eyeWhite);
    canvas.drawRect(Rect.fromLTWH(rightX, eyeY, eyeW, eyeH), eyeWhite);
    canvas.drawRect(Rect.fromLTWH(leftX + 2, eyeY + 2, 2, 2), eyePupil);
    canvas.drawRect(Rect.fromLTWH(rightX + 2, eyeY + 2, 2, 2), eyePupil);

    // небольшие "пропеллеры" по бокам (пиксели)
    final prop = Paint()..color = c.glow.withValues(alpha: 0.9);
    canvas.drawRect(Rect.fromLTWH(r.left - 4, r.center.dy - 2, 4, 4), prop);
    canvas.drawRect(Rect.fromLTWH(r.right, r.center.dy - 2, 4, 4), prop);
  }

  void _pixelGlowRect(Canvas canvas, Rect rect, Color fill, Color glow) {
    // glow слой
    final pGlow = Paint()
      ..color = glow.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRect(rect.inflate(3), pGlow);

    // пиксельная заливка: "блоки" 6x6
    const pix = 6.0;
    final pFill = Paint()..color = fill;
    for (double y = rect.top; y < rect.bottom; y += pix) {
      for (double x = rect.left; x < rect.right; x += pix) {
        // лёгкая шахматка, чтобы не было плоско
        final k = (((x / pix).floor() + (y / pix).floor()) % 2 == 0) ? 1.0 : 0.86;
        pFill.color = fill.withValues(alpha: 1.0).withRed((fill.red * k).round()).withGreen((fill.green * k).round()).withBlue((fill.blue * k).round());
        canvas.drawRect(Rect.fromLTWH(x, y, pix, pix), pFill);
      }
    }

    // обводка
    final pBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(1), pBorder);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.black);
  }
}

class _MenuDronePreview extends StatefulWidget {
  const _MenuDronePreview();

  @override
  State<_MenuDronePreview> createState() => _MenuDronePreviewState();
}

class _MenuDronePreviewState extends State<_MenuDronePreview> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2 * pi;
        final y = sin(t) * 10;
        final color = ((t / (2 * pi) * 3).floor()) % 3;
        return Transform.translate(
          offset: Offset(0, y),
          child: CustomPaint(
            size: const Size(140, 140),
            painter: _DronePreviewPainter(color: color),
          ),
        );
      },
    );
  }
}

class _DronePreviewPainter extends CustomPainter {
  final int color;
  _DronePreviewPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = PlayerColors.colors[color];
    final center = Offset(size.width / 2, size.height / 2);
    final r = Rect.fromCenter(center: center, width: 48, height: 48);
    final glow = Paint()
      ..color = c.glow.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawRect(r.inflate(4), glow);
    canvas.drawRect(r, Paint()..color = c.fill);

    // глазки
    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final eyePupil = Paint()..color = Colors.black.withValues(alpha: 0.85);
    canvas.drawRect(Rect.fromLTWH(r.left + 10, r.top + 12, 6, 6), eyeWhite);
    canvas.drawRect(Rect.fromLTWH(r.left + 32, r.top + 12, 6, 6), eyeWhite);
    canvas.drawRect(Rect.fromLTWH(r.left + 12, r.top + 14, 2, 2), eyePupil);
    canvas.drawRect(Rect.fromLTWH(r.left + 34, r.top + 14, 2, 2), eyePupil);
  }

  @override
  bool shouldRepaint(covariant _DronePreviewPainter oldDelegate) => oldDelegate.color != color;
}

class _NeonLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _NeonLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
        shadows: _neonTextShadows(color),
      ),
    );
  }
}

class _BigNeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _BigNeonButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF121222),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(shadows: _neonTextShadows(Colors.white)),
        ),
      ),
    );
  }
}

class _SmallNeonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const _SmallNeonButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, shadows: _neonTextShadows(Colors.white)),
      ),
    );
  }
}

List<Shadow> _neonTextShadows(Color c) {
  return [
    Shadow(color: c.withValues(alpha: 0.45), blurRadius: 10),
    Shadow(color: c.withValues(alpha: 0.25), blurRadius: 18),
  ];
}

/// =======================
/// Платформенные каналы.
/// =======================

class PlatformBridge {
  PlatformBridge._();
  static final instance = PlatformBridge._();

  static const _ch = MethodChannel('pixel_neon_drone_dash/platform');

  Future<void> openLeaderboard() async {
    try {
      await _ch.invokeMethod('openLeaderboard');
    } catch (_) {}
  }

  Future<bool> purchaseRemoveAds() async {
    try {
      final res = await _ch.invokeMethod<bool>('purchaseRemoveAds');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> shareText(String text) async {
    try {
      await _ch.invokeMethod('shareText', {'text': text});
    } catch (_) {}
  }
}

