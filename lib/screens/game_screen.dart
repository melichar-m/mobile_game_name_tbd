import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/player.dart';

// Helper function to normalize an Offset
Offset normalizeOffset(Offset offset) {
  double length = math.sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
  if (length == 0) return const Offset(0, 0);
  return Offset(offset.dx / length, offset.dy / length);
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Player player;
  Timer? gameLoop;
  Offset playerPosition = const Offset(0, 0);
  Offset moveDirection = const Offset(0, 0);
  Size? screenSize;
  Offset? touchStartPosition;
  Offset? currentTouchPosition;
  double maxControlRadius = 100.0;
  final int backgroundTiles = 5;
  double backgroundTileScale = 3.0;

  // Calculate the actual size of a single background tile
  Size get backgroundTileSize => Size(
    (screenSize?.width ?? 0) * backgroundTileScale,
    (screenSize?.height ?? 0) * backgroundTileScale,
  );

  // World bounds based on background image size
  double get worldWidth => backgroundTileSize.width * backgroundTiles;
  double get worldHeight => backgroundTileSize.height * backgroundTiles;

  @override
  void initState() {
    super.initState();
    player = Player();
    print('GameScreen initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        screenSize = MediaQuery.of(context).size;
        print('Screen size: ${screenSize?.width} x ${screenSize?.height}');
        print('Background tile size: ${backgroundTileSize.width} x ${backgroundTileSize.height}');
        print('World size: $worldWidth x $worldHeight');
        // Center the player in world space
        playerPosition = Offset(
          screenSize!.width / 2,
          screenSize!.height / 2,
        );
        print('Player position set to: ${playerPosition.dx}, ${playerPosition.dy}');
      });
    });
    startGameLoop();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  void startGameLoop() {
    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    if (screenSize == null) return;
    
    setState(() {
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
      }
      
      // Calculate new player position
      Offset newPlayerPosition = playerPosition + moveDirection * player.speed;
      
      // Clamp player position to world bounds
      newPlayerPosition = Offset(
        newPlayerPosition.dx.clamp(0, worldWidth),
        newPlayerPosition.dy.clamp(0, worldHeight),
      );
      
      // Update player position
      playerPosition = newPlayerPosition;
    });
  }

  Widget buildBackgroundTile() {
    return Transform.scale(
      scale: backgroundTileScale,
      child: Image.asset(
        'assets/images/background_placeholder.png',
        fit: BoxFit.cover,
        width: screenSize?.width ?? 0,
        height: screenSize?.height ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Game world
            Container(
              width: worldWidth,
              height: worldHeight,
              child: Stack(
                children: [
                  // Tiled background
                  ...List.generate(backgroundTiles * backgroundTiles, (index) {
                    int row = index ~/ backgroundTiles;
                    int col = index % backgroundTiles;
                    return Positioned(
                      left: col * (screenSize?.width ?? 0) * backgroundTileScale,
                      top: row * (screenSize?.height ?? 0) * backgroundTileScale,
                      child: buildBackgroundTile(),
                    );
                  }),
                  // Player
                  Positioned(
                    left: playerPosition.dx - 30,
                    top: playerPosition.dy - 30,
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
                ],
              ),
            ),
            // UI Overlay
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
            // Radial Control
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
            // Touch controls
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
          ],
        ),
      ),
    );
  }
} 