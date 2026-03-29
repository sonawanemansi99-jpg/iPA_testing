import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';

class CorporatorVideosPage extends StatefulWidget {
  const CorporatorVideosPage({super.key});

  @override
  State<CorporatorVideosPage> createState() => _CorporatorVideosPageState();
}

class _CorporatorVideosPageState extends State<CorporatorVideosPage>
    with TickerProviderStateMixin {

  // ── Brand Colors (matching MainScaffold) ──
  static const Color saffron     = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00);
  static const Color gold        = Color(0xFFFFD700);
  static const Color navyBlue    = Color(0xFF002868);
  static const Color darkNavy    = Color(0xFF001A45);
  static const Color white       = Color(0xFFFFFDF7);

  // ── Cloudinary config (from your JS) ──
  static const String _cloudName    = "dq18qyvol";
  static const String _uploadPreset = "flutter_unsigned";

  List<String> _videoUrls = [];
  bool _loadingVideos = true;
  bool _uploading     = false;
  double _uploadProgress = 0.0;
  String? _errorMsg;
  String? _successMsg;

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchVideos();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Fetch uploaded video URLs from Firestore ──
  Future<void> _fetchVideos() async {
    setState(() { _loadingVideos = true; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final urls = List<String>.from(data['uploadedVideoUrls'] ?? []);
        setState(() { _videoUrls = urls; });
      }
    } catch (e) {
      setState(() { _errorMsg = "Failed to load videos: $e"; });
    } finally {
      setState(() { _loadingVideos = false; });
    }
  }

  // ── Pick & upload video ──
  Future<void> _pickAndUploadVideo() async {
    setState(() { _errorMsg = null; _successMsg = null; });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final fileSize = await file.length();

    // 100 MB limit
    if (fileSize > 100 * 1024 * 1024) {
      setState(() { _errorMsg = "File too large. Maximum allowed size is 100 MB."; });
      return;
    }

    setState(() { _uploading = true; _uploadProgress = 0.0; });

    try {
      final url = await _uploadToCloudinary(file);
      if (url != null) {
        await _saveUrlToFirestore(url);
        setState(() {
          _videoUrls.add(url);
          _successMsg = "Video uploaded successfully!";
        });
      }
    } catch (e) {
      setState(() { _errorMsg = "Upload failed: $e"; });
    } finally {
      setState(() { _uploading = false; _uploadProgress = 0.0; });
    }
  }

  // ── Upload to Cloudinary (video resource type) ──
  Future<String?> _uploadToCloudinary(File file) async {
    final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/video/upload");

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["secure_url"] as String?;
    } else {
      throw Exception("Cloudinary error: ${response.body}");
    }
  }

  // ── Persist URL in Firestore users/{uid}.uploadedVideoUrls[] ──
  Future<void> _saveUrlToFirestore(String url) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    // Use arrayUnion so we never overwrite existing entries
    await ref.set(
      {"uploadedVideoUrls": FieldValue.arrayUnion([url])},
      SetOptions(merge: true),
    );
  }

  // ── Delete a video URL from Firestore ──
  Future<void> _deleteVideo(String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: darkNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Remove Video",
            style: TextStyle(color: white, fontWeight: FontWeight.w900)),
        content: const Text("Remove this video from your list?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: gold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      "uploadedVideoUrls": FieldValue.arrayRemove([url]),
    });

    setState(() { _videoUrls.remove(url); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [darkNavy, navyBlue, Color(0xFF003580)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _loadingVideos
                      ? const Center(
                          child: CircularProgressIndicator(color: gold))
                      : _buildBody(),
                ),
              ],
            ),
          ),

          // ── Upload progress overlay ──
          if (_uploading) _buildUploadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(0),
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // ── Top bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: gold.withOpacity(0.35)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: gold, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [gold, white, gold],
                ).createShader(bounds),
                child: const Text(
                  "MY VIDEOS",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const Spacer(),
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                        colors: [gold, saffron, deepSaffron]),
                    boxShadow: [
                      BoxShadow(
                          color: gold.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.videocam,
                      size: 18, color: darkNavy),
                ),
              ),
            ],
          ),
        ),

        // ── Gold divider ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Container(
            height: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, gold, Colors.transparent]),
            ),
          ),
        ),

        // ── Status messages ──
        if (_errorMsg != null)
          _statusBanner(_errorMsg!, isError: true),
        if (_successMsg != null)
          _statusBanner(_successMsg!, isError: false),

        // ── Upload button ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _uploading ? null : _pickAndUploadVideo,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [saffron, deepSaffron],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: saffron.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        "UPLOAD NEW VIDEO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Video grid ──
        Expanded(
          child: _videoUrls.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: _videoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _VideoCard(
                        url: _videoUrls[i],
                        index: i + 1,
                        onDelete: () => _deleteVideo(_videoUrls[i]),
                      ),
                ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined,
              color: gold.withOpacity(0.4), size: 72),
          const SizedBox(height: 16),
          Text(
            "No videos uploaded yet",
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap the button above to upload your first video",
            style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(String msg, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withOpacity(0.15)
            : Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isError
                ? Colors.redAccent.withOpacity(0.5)
                : Colors.greenAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : Colors.greenAccent,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color:
                        isError ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: darkNavy,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                  color: gold.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 4)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: gold, strokeWidth: 3),
              const SizedBox(height: 20),
              const Text(
                "UPLOADING VIDEO",
                style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                "Please wait...",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual video card with inline player ──
class _VideoCard extends StatefulWidget {
  final String url;
  final int index;
  final VoidCallback onDelete;

  const _VideoCard(
      {required this.url, required this.index, required this.onDelete});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  static const Color saffron  = Color(0xFFFF6700);
  static const Color gold     = Color(0xFFFFD700);
  static const Color darkNavy = Color(0xFF001A45);
  static const Color white    = Color(0xFFFFFDF7);

  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _showPlayer  = false;

  Future<void> _initPlayer() async {
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _controller!.initialize();
    setState(() { _initialized = true; });
    _controller!.play();
  }

  void _togglePlayer() async {
    if (!_showPlayer) {
      setState(() { _showPlayer = true; });
      await _initPlayer();
    } else {
      if (_controller?.value.isPlaying ?? false) {
        _controller?.pause();
      } else {
        _controller?.play();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: saffron.withOpacity(0.15),
                    border:
                        Border.all(color: saffron.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.videocam,
                      color: saffron, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  "Video ${widget.index}",
                  style: const TextStyle(
                      color: white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // ── Player / Thumbnail ──
          GestureDetector(
            onTap: _togglePlayer,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              height: 180,
              decoration: BoxDecoration(
                color: darkNavy,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: gold.withOpacity(0.15)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _showPlayer && _initialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                  colors: [gold, saffron]),
                              boxShadow: [
                                BoxShadow(
                                    color: gold.withOpacity(0.4),
                                    blurRadius: 16)
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: darkNavy, size: 32),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Tap to play",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // ── Play/Pause controls (shown after init) ──
          if (_showPlayer && _initialized)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_controller!.value.isPlaying) {
                        _controller!.pause();
                      } else {
                        _controller!.play();
                      }
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [saffron, Color(0xFFE55C00)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _controller!.value.isPlaying
                                ? "Pause"
                                : "Play",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}