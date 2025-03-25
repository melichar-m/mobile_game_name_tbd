import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../models/player.dart';
import 'package:flutter/services.dart';
import '../painters/background_painter.dart';
import '../painters/obstacle_painter.dart';
import '../utils/vector_utils.dart';
import '../generators/level_generator.dart';
import '../models/obstacle.dart';
import '../painters/enemy_painter.dart';
import '../managers/enemy_wave_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Player player;
  Timer? gameLoop;
  Offset playerPosition = const Offset(0, 0);
  Offset cameraPosition = const Offset(0, 0);
  Offset moveDirection = const Offset(0, 0);
  Size? screenSize;
  Offset? touchStartPosition;
  Offset? currentTouchPosition;
  double maxControlRadius = 100.0;
  final int backgroundTiles = 3;
  double backgroundTileScale = 2.0;
  ui.Image? backgroundImage;
  bool isLoading = true;
  int _lastUpdateTime = 0;

  // List of obstacles in world space
  late List<Obstacle> obstacles;

  late EnemyWaveManager enemyWaveManager;
  bool isGameStarted = false;

  // Calculate the actual size of a single background tile
  Size get backgroundTileSize => Size(
    (screenSize?.width ?? 0),
    (screenSize?.height ?? 0),
  );

  // World bounds based on background image size
  double get worldWidth => backgroundTileSize.width * backgroundTiles * backgroundTileScale;
  double get worldHeight => backgroundTileSize.height * backgroundTiles * backgroundTileScale;

  // Calculate screen boundaries (50% of screen size)
  double get screenBoundaryX => (screenSize?.width ?? 0) * 0.3;
  double get screenBoundaryY => (screenSize?.height ?? 0) * 0.3;

  // Helper method to check if a position collides with any obstacle
  bool checkCollision(Offset position) {
    final playerRect = Rect.fromCenter(
      center: position,
      width: 60,  // Match player width
      height: 60, // Match player height
    );

    for (final obstacle in obstacles) {
      if (playerRect.overlaps(obstacle.bounds)) {
        return true;
      }
    }
    return false;
  }

  // Helper method to get adjusted movement vector when colliding
  Offset getAdjustedMovement(Offset currentPos, Offset movement) {
    // Try the full movement first
    Offset newPos = currentPos + movement;
    if (!checkCollision(newPos)) {
      return movement;
    }

    // If collision occurs, try horizontal movement only
    Offset horizontalMove = Offset(movement.dx, 0);
    if (!checkCollision(currentPos + horizontalMove)) {
      return horizontalMove;
    }

    // If horizontal collision occurs, try vertical movement only
    Offset verticalMove = Offset(0, movement.dy);
    if (!checkCollision(currentPos + verticalMove)) {
      return verticalMove;
    }

    // If both directions cause collision, return zero movement
    return Offset.zero;
  }

  void generateNewLevel() {
    // Create level generator with world size
    final generator = LevelGenerator(
      worldSize: Size(worldWidth, worldHeight),
      minObstacles: 15,
      maxObstacles: 25,
      minSpacing: 120,
    );

    // Generate obstacles with safe zone around player start position
    obstacles = generator.generateObstacles(
      playerStart: Offset(worldWidth / 2, worldHeight / 2),
    );
  }

  @override
  void initState() {
    super.initState();
    player = Player();
    // Initialize obstacles list
    obstacles = [];
    _loadBackgroundImage();
    print('GameScreen initialized');
    
    // Initialize enemyWaveManager with default values
    enemyWaveManager = EnemyWaveManager(
      screenSize: const Size(800, 600), // Default size, will be updated
      worldWidth: 3000, // Default size, will be updated
      worldHeight: 3000, // Default size, will be updated
    );
  }

  Future<void> _loadBackgroundImage() async {
    // Load the image
    final ByteData data = await rootBundle.load('assets/images/background_placeholder.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    
    setState(() {
      backgroundImage = fi.image;
      isLoading = false;
      
      // Initialize screen size and start game loop after image is loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          screenSize = MediaQuery.of(context).size;
          print('Screen size: ${screenSize?.width} x ${screenSize?.height}');
          print('Background tile size: ${backgroundTileSize.width} x ${backgroundTileSize.height}');
          print('World size: $worldWidth x $worldHeight');
          
          // Start player at world center
          playerPosition = Offset(
            worldWidth / 2,
            worldHeight / 2,
          );
          
          // Generate the level
          generateNewLevel();
          
          // Set camera to center on player
          cameraPosition = Offset(
            playerPosition.dx - (screenSize!.width / 2),
            playerPosition.dy - (screenSize!.height / 2),
          );

          // Update enemyWaveManager with correct dimensions
          enemyWaveManager = EnemyWaveManager(
            screenSize: screenSize!,
            worldWidth: worldWidth,
            worldHeight: worldHeight,
          );
          
          print('Player position set to: ${playerPosition.dx}, ${playerPosition.dy}');
          print('Camera position set to: ${cameraPosition.dx}, ${cameraPosition.dy}');
        });
        startGameLoop();
      });
    });
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  void startGameLoop() {
    _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
    const frameRate = Duration(milliseconds: 16); // ~60 FPS
    gameLoop = Timer.periodic(frameRate, (timer) {
      if (mounted) {
        updateGame();
      }
    });
  }

  void updateGame() {
    if (screenSize == null) return;

    // Calculate delta time in seconds
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final deltaTime = (currentTime - _lastUpdateTime) / 1000.0;
    _lastUpdateTime = currentTime;

    setState(() {
      // Handle player movement
      if (touchStartPosition != null && currentTouchPosition != null) {
        // Calculate the vector from touch start to current position
        Offset delta = currentTouchPosition! - touchStartPosition!;
        
        // Calculate the distance from the center
        double distance = math.sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
        
        // If the distance is greater than maxControlRadius, clamp it
        if (distance > maxControlRadius) {
          delta = normalizeOffset(delta) * maxControlRadius;
        }
        
        // Calculate the movement speed based on distance (0 to 1)
        double speedMultiplier = (distance / maxControlRadius).clamp(0.0, 1.0);
        
        // Set the movement direction and speed
        moveDirection = normalizeOffset(delta);
        player.speed = 5.0 * speedMultiplier;
      } else {
        // Reset movement when no touch
        moveDirection = Offset.zero;
        player.speed = 0.0;
      }

      // Calculate intended movement
      Offset intendedMovement = moveDirection * player.speed;
      
      // Get adjusted movement that accounts for collisions
      Offset actualMovement = getAdjustedMovement(playerPosition, intendedMovement);
      
      // Update player position
      playerPosition += actualMovement;
      
      // Clamp player position to world bounds with padding
      double padding = 30.0; // Half the player size
      playerPosition = Offset(
        playerPosition.dx.clamp(padding, worldWidth - padding),
        playerPosition.dy.clamp(padding, worldHeight - padding),
      );

      // Update camera to follow player smoothly
      cameraPosition = Offset(
        playerPosition.dx - (screenSize!.width / 2),
        playerPosition.dy - (screenSize!.height / 2),
      );
      
      // Clamp camera to prevent seeing beyond world bounds
      cameraPosition = Offset(
        cameraPosition.dx.clamp(0, math.max(0, worldWidth - screenSize!.width)),
        cameraPosition.dy.clamp(0, math.max(0, worldHeight - screenSize!.height)),
      );

      // Update enemies with proper deltaTime
      enemyWaveManager.update(deltaTime, playerPosition);

      // Debug enemy positions occasionally
      if (DateTime.now().millisecondsSinceEpoch % 1000 < 16) {
        print('Player position: $playerPosition');
        print('Number of active enemies: ${enemyWaveManager.enemies.length}');
        for (final enemy in enemyWaveManager.enemies) {
          print('${enemy.type.name} enemy at ${enemy.position}, distance: ${(enemy.position - playerPosition).distance}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || backgroundImage == null || screenSize == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Layer 1: Background with CustomPainter
            CustomPaint(
              painter: BackgroundPainter(
                backgroundImage: backgroundImage!,
                cameraPosition: cameraPosition,
                scale: 2.0,
              ),
              size: Size(screenSize!.width, screenSize!.height),
            ),
            // Layer 2: Obstacles
            CustomPaint(
              painter: ObstaclePainter(
                cameraPosition: cameraPosition,
                obstacles: obstacles,
                images: const {}, // TODO: Add obstacle images
              ),
              size: Size(screenSize!.width, screenSize!.height),
            ),
            // Layer 3: Enemies
            CustomPaint(
              painter: EnemyPainter(
                enemies: enemyWaveManager.enemies,
                cameraPosition: cameraPosition,
              ),
              size: Size(screenSize!.width, screenSize!.height),
            ),
            // Layer 4: Player
            Positioned(
              left: playerPosition.dx - cameraPosition.dx - 30,
              top: playerPosition.dy - cameraPosition.dy - 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
            ),
            // Layer 5: UI Elements (no camera transform)
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level: ${player.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'HP: ${player.health.toStringAsFixed(1)}/${player.maxHealth}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Wave counter
            Positioned(
              top: 20,
              right: 20,
              child: Text(
                'Wave: ${enemyWaveManager.currentWave}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Radial Control (UI layer)
            if (touchStartPosition != null && currentTouchPosition != null)
              Positioned(
                left: touchStartPosition!.dx - maxControlRadius,
                top: touchStartPosition!.dy - maxControlRadius,
                child: Container(
                  width: maxControlRadius * 2,
                  height: maxControlRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: maxControlRadius + (currentTouchPosition!.dx - touchStartPosition!.dx).clamp(-maxControlRadius, maxControlRadius),
                        top: maxControlRadius + (currentTouchPosition!.dy - touchStartPosition!.dy).clamp(-maxControlRadius, maxControlRadius),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Touch controls (UI layer)
            GestureDetector(
              onPanStart: (details) {
                setState(() {
                  touchStartPosition = details.globalPosition;
                  currentTouchPosition = details.globalPosition;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  currentTouchPosition = details.globalPosition;
                });
              },
              onPanEnd: (_) {
                setState(() {
                  touchStartPosition = null;
                  currentTouchPosition = null;
                  moveDirection = const Offset(0, 0);
                  player.speed = 5.0;
                });
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
            // Start Wave Button (when no wave is active)
            if (!isGameStarted || (enemyWaveManager.enemies.isEmpty && enemyWaveManager.enemiesRemainingInWave == 0))
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (!isGameStarted) {
                        isGameStarted = true;
                        enemyWaveManager.startNextWave();
                      } else {
                        // Start next wave if previous wave is complete
                        enemyWaveManager.startNextWave();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    !isGameStarted ? 'Start Game' : 'Start Wave ${enemyWaveManager.currentWave + 1}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Enemies remaining counter (when wave is active)
            if (isGameStarted && (enemyWaveManager.enemies.isNotEmpty || enemyWaveManager.enemiesRemainingInWave > 0))
              Positioned(
                top: 60,
                right: 20,
                child: Text(
                  'Enemies: ${enemyWaveManager.enemies.length + enemyWaveManager.enemiesRemainingInWave}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 