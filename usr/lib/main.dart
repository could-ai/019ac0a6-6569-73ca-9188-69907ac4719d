import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Dodge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050510),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Game State
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  double playerX = 0.0;
  
  // Configuration
  late double screenWidth;
  late double screenHeight;
  final double playerSize = 50.0;
  final double enemySize = 40.0;
  double gameSpeed = 3.0;
  
  // Entities
  List<Enemy> enemies = [];
  List<Star> stars = [];
  
  // Loop
  late Ticker _ticker;
  final Random _random = Random();
  int _spawnTimer = 0;

  @override
  void initState() {
    super.initState();
    // Ticker runs every frame (approx 60fps)
    _ticker = createTicker(_onTick);
    
    // Hide status bar for immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    playerX = screenWidth / 2 - playerSize / 2;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      isGameOver = false;
      score = 0;
      enemies.clear();
      stars.clear();
      gameSpeed = 4.0;
      playerX = screenWidth / 2 - playerSize / 2;
    });
    _ticker.start();
  }

  void _stopGame() {
    _ticker.stop();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
  }

  void _onTick(Duration elapsed) {
    if (!isPlaying) return;

    setState(() {
      // 1. Spawn Enemies
      _spawnTimer++;
      if (_spawnTimer > (60 - score / 50).clamp(20, 60)) { // Spawn faster as score increases
        _spawnTimer = 0;
        enemies.add(Enemy(
          x: _random.nextDouble() * (screenWidth - enemySize),
          y: -enemySize,
          speed: gameSpeed + _random.nextDouble() * 2,
          color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        ));
      }

      // 2. Spawn Background Stars (Visual effect)
      if (_random.nextInt(10) == 0) {
        stars.add(Star(
          x: _random.nextDouble() * screenWidth,
          y: -5.0,
          speed: 1.0 + _random.nextDouble() * 3,
          size: 1.0 + _random.nextDouble() * 2,
        ));
      }

      // 3. Update Enemies
      for (var enemy in enemies) {
        enemy.y += enemy.speed;
      }

      // 4. Update Stars
      for (var star in stars) {
        star.y += star.speed;
      }

      // 5. Cleanup off-screen entities
      enemies.removeWhere((e) {
        if (e.y > screenHeight) {
          score += 10; // Score for dodging
          if (score % 100 == 0) gameSpeed += 0.5; // Increase difficulty
          return true;
        }
        return false;
      });
      stars.removeWhere((s) => s.y > screenHeight);

      // 6. Collision Detection
      final playerRect = Rect.fromLTWH(playerX + 10, screenHeight - 100, playerSize - 20, playerSize - 20);
      
      for (var enemy in enemies) {
        final enemyRect = Rect.fromLTWH(enemy.x, enemy.y, enemySize, enemySize);
        if (playerRect.overlaps(enemyRect)) {
          _stopGame();
          break;
        }
      }
    });
  }

  void _updatePlayerPosition(DragUpdateDetails details) {
    if (!isPlaying) return;
    setState(() {
      playerX += details.delta.dx;
      // Keep player within screen bounds
      playerX = playerX.clamp(0.0, screenWidth - playerSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: _updatePlayerPosition,
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
                ),
              ),
            ),

            // Stars
            ...stars.map((star) => Positioned(
              left: star.x,
              top: star.y,
              child: Container(
                width: star.size,
                height: star.size,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )),

            // Player
            Positioned(
              left: playerX,
              top: screenHeight - 100,
              child: Container(
                width: playerSize,
                height: playerSize,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch, color: Colors.black),
              ),
            ),

            // Enemies
            ...enemies.map((enemy) => Positioned(
              left: enemy.x,
              top: enemy.y,
              child: Container(
                width: enemySize,
                height: enemySize,
                decoration: BoxDecoration(
                  color: enemy.color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: enemy.color.withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              ),
            )),

            // Score Display
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Score: $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.blue, blurRadius: 10)],
                  ),
                ),
              ),
            ),

            // Start / Game Over Screen
            if (!isPlaying)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isGameOver ? 'GAME OVER' : 'NEON DODGE',
                        style: TextStyle(
                          color: isGameOver ? Colors.redAccent : Colors.cyanAccent,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isGameOver)
                        Text(
                          'Final Score: $score',
                          style: const TextStyle(color: Colors.white70, fontSize: 24),
                        ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          isGameOver ? 'RETRY' : 'START GAME',
                          style: const TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Drag left/right to dodge',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper Classes
class Enemy {
  double x;
  double y;
  double speed;
  Color color;

  Enemy({required this.x, required this.y, required this.speed, required this.color});
}

class Star {
  double x;
  double y;
  double speed;
  double size;

  Star({required this.x, required this.y, required this.speed, required this.size});
}
