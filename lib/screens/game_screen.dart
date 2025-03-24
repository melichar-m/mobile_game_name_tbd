import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../models/player.dart';
import 'package:flutter/services.dart';
import '../painters/background_painter.dart';
import '../painters/obstacle_painter.dart';
import '../utils/vector_utils.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
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

  // List of obstacles in world space
  final List<Rect> obstacles = [
    Rect.fromLTWH(500, 300, 100, 100),  // Example obstacle
  ];

  // Calculate the actual size of a single background tile
  Size get backgroundTileSize => Size(
    (screenSize?.width ?? 0),  // Remove scaling from size calculation
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
      if (playerRect.overlaps(obstacle)) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    player = Player();
    _loadBackgroundImage();
    print('GameScreen initialized');
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
          
          // Start player at screen center
          playerPosition = Offset(
            screenSize!.width / 2,
            screenSize!.height / 2,
          );
          
          // Set camera to center on player
          cameraPosition = Offset(
            playerPosition.dx - (screenSize!.width / 2),
            playerPosition.dy - (screenSize!.height / 2),
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
      
      // Check for collision at new position
      if (!checkCollision(newPlayerPosition)) {
        // Only update position if there's no collision
        // Clamp player position to world bounds with padding
        double padding = 30.0; // Half the player size
        newPlayerPosition = Offset(
          newPlayerPosition.dx.clamp(padding, worldWidth - padding),
          newPlayerPosition.dy.clamp(padding, worldHeight - padding),
        );
        
        // Update player position
        playerPosition = newPlayerPosition;
      }

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
              ),
              size: Size(screenSize!.width, screenSize!.height),
            ),
            // Layer 2: Player with camera transform
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
            // Layer 3: UI Elements (no camera transform)
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
          ],
        ),
      ),
    );
  }
} 