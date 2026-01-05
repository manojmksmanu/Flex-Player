import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF1a1a1a),
      ),
      home: const VideoListScreen(),
    );
  }
}

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({Key? key}) : super(key: key);

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<File> videos = [];
  bool isLoading = true;
  String statusMessage = 'Videos scan ho rahi hain...';

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  Future<void> loadVideos() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Permission check ho rahi hai...';
    });

    try {
      bool permissionGranted = await requestPermissions();

      if (permissionGranted) {
        setState(() {
          statusMessage = 'Videos scan ho rahi hain...';
        });
        await scanForVideos();
      } else {
        setState(() {
          statusMessage = 'Permission nahi mili. Settings se permission dein.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await getAndroidVersion();

      if (androidInfo >= 33) {
        // Android 13+
        final videos = await Permission.videos.request();
        final photos = await Permission.photos.request();
        return videos.isGranted || photos.isGranted;
      } else {
        // Android 12 and below
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }
    return true;
  }

  Future<int> getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        var androidInfo = await Permission.storage.status;
        return 33; // Default to 33 for safety
      }
    } catch (e) {
      print('Error getting Android version: $e');
    }
    return 33;
  }

  Future<void> scanForVideos() async {
    List<File> foundVideos = [];
    List<String> searchPaths = [];

    if (Platform.isAndroid) {
      searchPaths = [
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
        '/storage/emulated/0/Telegram/Telegram Video',
      ];
    }

    int scannedFolders = 0;
    for (String path in searchPaths) {
      try {
        setState(() {
          statusMessage =
              'Scanning: ${path.split('/').last}... ($scannedFolders/${searchPaths.length})';
        });

        final dir = Directory(path);
        if (await dir.exists()) {
          await for (var entity in dir.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is File && isVideoFile(entity.path)) {
              foundVideos.add(entity);
              if (foundVideos.length % 10 == 0) {
                setState(() {
                  statusMessage = '${foundVideos.length} videos mili...';
                });
              }
            }
          }
        }
        scannedFolders++;
      } catch (e) {
        print('Error scanning $path: $e');
      }
    }

    setState(() {
      videos = foundVideos;
      isLoading = false;
    });
  }

  bool isVideoFile(String path) {
    final extensions = [
      '.mp4',
      '.mkv',
      '.avi',
      '.mov',
      '.wmv',
      '.flv',
      '.3gp',
      '.m4v',
      '.webm',
    ];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📹 Video Player',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2d2d2d),
        elevation: 0,
        actions: [
          if (videos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  label: Text(
                    '${videos.length} videos',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadVideos,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.orange),
                  const SizedBox(height: 20),
                  Text(
                    statusMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${videos.length} videos mili',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            )
          : videos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 100,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Koi video nahi mili',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      statusMessage,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: loadVideos,
                    icon: const Icon(Icons.refresh, size: 28),
                    label: const Text(
                      'Dobara Scan Karein',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => openAppSettings(),
                    child: const Text('Settings mein jao'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                final fileName = video.path.split('/').last;
                final fileSize = video.lengthSync();

                return Card(
                  color: const Color(0xFF2d2d2d),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VideoPlayerScreen(videoFile: video),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.play_circle_filled,
                              color: Colors.orange,
                              size: 35,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  formatFileSize(fileSize),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;

  const VideoPlayerScreen({Key? key, required this.videoFile})
    : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  Timer? _hideTimer;
  double _currentSliderValue = 0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      })
      ..addListener(() {
        if (mounted) {
          setState(() {
            _currentSliderValue = _controller.value.position.inSeconds
                .toDouble();
          });
        }
      });

    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text(
                widget.videoFile.path.split('/').last,
                style: const TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.black,
            ),
      body: GestureDetector(
        onTap: _toggleControls,
        child: Center(
          child: _isInitialized
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    if (_showControls)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        if (_isFullScreen) {
                                          _toggleFullScreen();
                                        }
                                        Navigator.pop(context);
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        widget.videoFile.path.split('/').last,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.replay_10,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    onPressed: () {
                                      final newPos =
                                          _controller.value.position -
                                          const Duration(seconds: 10);
                                      _controller.seekTo(
                                        newPos < Duration.zero
                                            ? Duration.zero
                                            : newPos,
                                      );
                                      _startHideTimer();
                                    },
                                  ),
                                  const SizedBox(width: 30),
                                  IconButton(
                                    icon: Icon(
                                      _controller.value.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _controller.value.isPlaying
                                            ? _controller.pause()
                                            : _controller.play();
                                      });
                                      _startHideTimer();
                                    },
                                  ),
                                  const SizedBox(width: 30),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.forward_10,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    onPressed: () {
                                      final newPos =
                                          _controller.value.position +
                                          const Duration(seconds: 10);
                                      _controller.seekTo(
                                        newPos > _controller.value.duration
                                            ? _controller.value.duration
                                            : newPos,
                                      );
                                      _startHideTimer();
                                    },
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 10,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 20,
                                            ),
                                      ),
                                      child: Slider(
                                        value: _currentSliderValue,
                                        min: 0,
                                        max: _controller
                                            .value
                                            .duration
                                            .inSeconds
                                            .toDouble(),
                                        activeColor: Colors.orange,
                                        inactiveColor: Colors.grey[600],
                                        onChanged: (value) {
                                          setState(() {
                                            _currentSliderValue = value;
                                          });
                                          _controller.seekTo(
                                            Duration(seconds: value.toInt()),
                                          );
                                          _startHideTimer();
                                        },
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(
                                            _controller.value.position,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _isFullScreen
                                                ? Icons.fullscreen_exit
                                                : Icons.fullscreen,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          onPressed: () {
                                            _toggleFullScreen();
                                            _startHideTimer();
                                          },
                                        ),
                                        Text(
                                          _formatDuration(
                                            _controller.value.duration,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 20),
                    Text(
                      'Video load ho raha hai...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
