import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video.dart';
import 'dart:developer' as developer;
import '../utils/tier_colors.dart';

class VideoOverlayPlayer extends StatefulWidget {
  final Video video;
  final bool showSubmitButton; // 제출 버튼 표시 여부
  final TierColorScheme? tierColors;

  const VideoOverlayPlayer({
    super.key,
    required this.video,
    this.showSubmitButton = true, // 기본값은 true
    this.tierColors,
  });

  @override
  State<VideoOverlayPlayer> createState() => _VideoOverlayPlayerState();
}

class _VideoOverlayPlayerState extends State<VideoOverlayPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.hlsCdnUrl!),
    );
    _initializeVideoPlayerFuture = _controller
        .initialize()
        .then((_) {
          _controller.play();
          _startHideControlsTimer();
        })
        .catchError((error) {
          developer.log(
            'Video initialization error: $error',
            name: 'VideoPlayer',
          );
        });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _closePlayer() {
    Navigator.of(context).pop();
  }

  void _togglePlayPause() {
    _resetHideControlsTimer();
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _resetHideControlsTimer();
      } else {
        _hideControlsTimer?.cancel();
      }
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _resetHideControlsTimer() {
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    // 전달받은 색상을 사용하거나, 기본 색상 사용
    final TierColorScheme colorScheme = widget.tierColors ?? 
      TierColors.getColorScheme(TierColors.getTierFromString('Bronze III'));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.black,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 40,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      !snapshot.hasError) {
                    return GestureDetector(
                      onTap: _toggleControlsVisibility,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                          Positioned.fill(
                            child: AnimatedOpacity(
                              opacity: _showControls ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: IgnorePointer(
                                ignoring: !_showControls,
                                child: _buildControls(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        '영상을 불러오는데 실패했습니다.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 제출 버튼이 표시되어야 할 때만 표시
          if (widget.showSubmitButton) _buildSubmitButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black.withValues(alpha: 0.2),
      child: Stack(
        children: [
          Center(
            child: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, VideoPlayerValue value, child) {
                return GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: _closePlayer,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(TierColorScheme tierColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('영상 제출 기능은 준비 중입니다')));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: tierColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, size: 20),
            SizedBox(width: 8),
            Text(
              '영상 제출하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
