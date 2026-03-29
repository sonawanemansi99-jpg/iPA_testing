import 'package:audioplayers/audioplayers.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/status_badge.dart';
import 'package:corporator_app/services/complaint_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ListComplaints extends StatefulWidget {
  final String adminId;
  const ListComplaints({super.key, required this.adminId});

  @override
  State<ListComplaints> createState() => _ListComplaintsState();
}

class _ListComplaintsState extends State<ListComplaints>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  // ── Role awareness ──
  String _currentRole = '';
  String? adminName;

  final ComplaintService _complaintService = ComplaintService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  List<Map<String, dynamic>> allComplaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];

  String selectedStatus = "all";
  bool isLoading = true;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // ── Brand Colors ──
  static const Color saffron = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00);
  static const Color gold = Color(0xFFFFD700);
  static const Color navyBlue = Color(0xFF002868);
  static const Color darkNavy = Color(0xFF001A45);
  static const Color ashoka = Color(0xFF1A6FAB);
  static const Color warmWhite = Color(0xFFFFFDF7);
  static const Color indiaGreen = Color(0xFF138808);

  bool get _isCorporator => _currentRole.toUpperCase() == 'CORPORATOR' || _currentRole.toUpperCase() == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      // 1. Check local storage for UI Role and Name
      final storedRole = await _storage.read(key: 'role') ?? '';
      final storedName = await _storage.read(key: 'name') ?? 'Official';
      
      // 2. Fetch the data! The backend auto-filters based on the JWT token
      final complaints = await _complaintService.fetchComplaints();

      if (mounted) {
        setState(() {
          _currentRole = storedRole;
          adminName = storedName;
          allComplaints = complaints;
          filteredComplaints = _applyStatusFilter(complaints);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Voice player — icon only ──
  Widget _voicePlayer(String voiceUrl, String complaintId) {
    final bool isPlaying = _currentlyPlayingId == complaintId;

    return GestureDetector(
      onTap: () async {
        try {
          if (isPlaying) {
            await _audioPlayer.stop();
            setState(() => _currentlyPlayingId = null);
          } else {
            await _audioPlayer.stop();
            await _audioPlayer.play(UrlSource(voiceUrl));
            setState(() => _currentlyPlayingId = complaintId);
            _audioPlayer.onPlayerComplete.listen((_) {
              if (mounted) setState(() => _currentlyPlayingId = null);
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Audio Error: $e")));
          }
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isPlaying
                ? [indiaGreen, Colors.green]
                : [saffron, deepSaffron],
          ),
          boxShadow: [
            BoxShadow(
              color: (isPlaying ? indiaGreen : saffron).withOpacity(0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> get _statusConfig => {
        'all': {
          'label': 'ALL',
          'icon': Icons.list_alt,
          'color': navyBlue,
          'hindi': 'सभी',
        },
        'pending': {
          'label': 'PENDING',
          'icon': Icons.hourglass_top,
          'color': const Color(0xFFCC3300),
          'hindi': 'लंबित',
        },
        'in progress': {
          'label': 'IN PROGRESS',
          'icon': Icons.construction,
          'color': saffron,
          'hindi': 'प्रगति में',
        },
        'complete': {
          'label': 'COMPLETE',
          'icon': Icons.check_circle,
          'color': indiaGreen,
          'hindi': 'पूर्ण',
        },
      };
    
  List<Map<String, dynamic>> _applyStatusFilter(List<Map<String, dynamic>> source) {
    if (selectedStatus == "all") return source;
    return source.where((c) {
      final status = c['status']?.toString() ?? 'pending';
      return status.toLowerCase() == selectedStatus.toLowerCase();
    }).toList();
  }

  void applyFilter(String status) {
    setState(() {
      selectedStatus = status;
      filteredComplaints = _applyStatusFilter(allComplaints);
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ── Image helpers ──
  void displayFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 5,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, prog) => prog == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget imageTile(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => displayFullImage(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            height: 150,
            width: double.infinity,
            loadingBuilder: (_, child, prog) => prog == null
                ? child
                : SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: prog.expectedTotalBytes != null
                            ? prog.cumulativeBytesLoaded /
                                prog.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void showImagesDialog(
    BuildContext context,
    List<String> citizenImages,
    List<String> adminImages,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: warmWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.4), blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [darkNavy, navyBlue]),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: const Text(
                  "COMPLAINT IMAGES",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (citizenImages.isNotEmpty) ...[
                        _sectionLabel(
                            "नागरिक द्वारा अपलोड", "Citizen Images"),
                        const SizedBox(height: 10),
                        ...citizenImages.map(imageTile),
                        const SizedBox(height: 12),
                      ],
                      if (adminImages.isNotEmpty) ...[
                        _sectionLabel(
                            "प्रशासन द्वारा अपलोड", "Admin Images"),
                        const SizedBox(height: 10),
                        ...adminImages.map(imageTile),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: saffron,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "CLOSE",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String hindi, String english) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: saffron,
          margin: const EdgeInsets.only(right: 10),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hindi,
              style: const TextStyle(
                fontSize: 11,
                color: saffron,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            Text(
              english,
              style: const TextStyle(
                fontSize: 15,
                color: darkNavy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulseAnim =
        _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return MainScaffold(
      title: _isCorporator ? "All Complaints" : "Complaints",
      floatingActionButton: ScaleTransition(
        scale: isLoading ? pulseAnim : const AlwaysStoppedAnimation(1.0),
        child: FloatingActionButton(
          onPressed: _refresh,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [saffron, deepSaffron],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: saffron.withOpacity(0.55),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: gold, width: 2),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white, size: 26),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkNavy, navyBlue, Color(0xFF003A8C)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ChakraPatternPainter()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [saffron, gold, saffron]),
                  ),
                ),
                _isCorporator
                    ? _buildCorporatorHeader()
                    : _buildAdminHeader(),
                if (!isLoading) _buildStatsRow(),
                _buildFilterRow(),
                Expanded(child: _buildComplaintList()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Corporator header ──
  Widget _buildCorporatorHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [gold, saffron]),
              boxShadow: [
                BoxShadow(color: gold.withOpacity(0.5), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.account_balance,
                color: darkNavy, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CORPORATOR DASHBOARD",
                  style: TextStyle(
                    color: gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "All Ward Complaints",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: saffron.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: saffron, width: 1),
            ),
            child: Text(
              "${allComplaints.length}\nCOMPLAINTS",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: saffron,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Zone Sevak header ──
  Widget _buildAdminHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [gold, saffron]),
              boxShadow: [
                BoxShadow(color: gold.withOpacity(0.5), blurRadius: 12),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: darkNavy, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ZONE SEVAK",
                  style: TextStyle(
                    color: gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  adminName ?? "Official",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: saffron.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: saffron, width: 1),
            ),
            child: Text(
              "${allComplaints.length}\nCOMPLAINTS",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: saffron,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final pending = allComplaints
        .where((c) => (c['status'] ?? '').toString().toLowerCase() == 'pending')
        .length;
    final inProgress = allComplaints
        .where((c) => (c['status'] ?? '').toString().toLowerCase() == 'in_progress' || (c['status'] ?? '').toString().toLowerCase() == 'in progress')
        .length;
    final complete = allComplaints
        .where((c) => (c['status'] ?? '').toString().toLowerCase() == 'completed' || (c['status'] ?? '').toString().toLowerCase() == 'complete')
        .length;
        
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          _statChip(pending.toString(), "PENDING",
              const Color(0xFFCC3300), Icons.hourglass_top),
          const SizedBox(width: 8),
          _statChip(inProgress.toString(), "PROGRESS", saffron,
              Icons.construction),
          const SizedBox(width: 8),
          _statChip(complete.toString(), "COMPLETE", indiaGreen,
              Icons.check_circle),
        ],
      ),
    );
  }

  Widget _statChip(
      String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Column(
              children: [
                Text(
                  count,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusConfig.entries.map((entry) {
            final key = entry.key;
            final config = entry.value;
            final selected = selectedStatus == key;
            final color = config['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => applyFilter(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          )
                        : null,
                    color: selected
                        ? null
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? color
                          : Colors.white.withOpacity(0.2),
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        config['icon'] as IconData,
                        color:
                            selected ? Colors.white : Colors.white60,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config['hindi'] as String,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white70
                                  : Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            config['label'] as String,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildComplaintList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [gold, saffron]),
                boxShadow: [
                  BoxShadow(
                      color: gold.withOpacity(0.4), blurRadius: 20),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: darkNavy,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "लोड हो रहा है...",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }
    if (filteredComplaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inbox_outlined, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text(
              "कोई शिकायत नहीं मिली",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "No complaints found",
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: filteredComplaints.length,
      itemBuilder: (_, i) =>
          _buildComplaintCard(filteredComplaints[i], i),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint, int index) {
    // ── Safe JSON Extraction ──
    final status = complaint['status']?.toString() ?? 'PENDING';
    final id = complaint['id']?.toString() ?? complaint['complaintId']?.toString() ?? 'N/A';
    final name = complaint['citizenName'] ?? complaint['name'] ?? 'Unknown';
    final zoneName = complaint['zoneName'] ?? 'Unknown Zone';
    final mobileNo = complaint['mobileNumber'] ?? complaint['mobileNo'] ?? 'N/A';
    
    // Arrays and Media
    final citizenImages = List<String>.from(complaint['evidenceImageUrls'] ?? []);
    
    // If the backend doesn't currently provide admin images, fallback to empty list
    final adminImages = complaint.containsKey('resolutionImageUrl') && complaint['resolutionImageUrl'] != null 
                        ? [complaint['resolutionImageUrl'].toString()] 
                        : <String>[];
                        
    final citizenVoiceNote = complaint['descriptionVoiceNoteUrl'] ?? '';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = const Color(0xFFCC3300);
        break;
      case 'in_progress':
      case 'in progress':
        statusColor = saffron;
        break;
      case 'completed':
      case 'complete':
        statusColor = indiaGreen;
        break;
      default:
        statusColor = ashoka;
    }

    final bool hasVoice = citizenVoiceNote.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        // onTap: () => Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (_) => ComplainDetails(complaintMap: complaint), // Assumes ComplainDetails accepts Map
        //   ),
        // ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: warmWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: statusColor.withOpacity(0.12),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── ID + Status ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: navyBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "#${index + 1}",
                              style: const TextStyle(
                                color: gold,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              id,
                              style: const TextStyle(
                                color: darkNavy,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          statusBadge(status),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Info tiles ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _infoTile(Icons.person_outline, "Name",
                                    name),
                                const SizedBox(height: 8),
                                _infoTile(
                                    Icons.location_city_outlined,
                                    "Zone",
                                    zoneName),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _infoTile(Icons.phone_outlined,
                                "Mobile", mobileNo),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── Action buttons ──
                      Row(
                        children: [
                          // UPDATE STATUS — always shown for admin
                          if (!_isCorporator)
                            Expanded(
                              child: GestureDetector(
                                // onTap: () => Navigator.of(context)
                                //     .push(
                                //       MaterialPageRoute(
                                //         builder: (_) =>
                                //             EditComplaintStatus(
                                //                 complaintMap: complaint), // Assumes Edit accepts Map
                                //       ),
                                //     )
                                //     .then((_) => _refresh()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [navyBlue, darkNavy],
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            navyBlue.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          color: gold, size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        "UPDATE STATUS",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          if (!_isCorporator) const SizedBox(width: 8),

                          // PHOTOS — always shown, expands for corporator
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showImagesDialog(
                                context,
                                citizenImages,
                                adminImages,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 9),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [saffron, deepSaffron],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          saffron.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "PHOTOS",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // VOICE NOTE — icon only, only if voice note exists
                          if (hasVoice) ...[
                            const SizedBox(width: 8),
                            _voicePlayer(
                              citizenVoiceNote,
                              id,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Left status strip
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 6, color: statusColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: saffron, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: darkNavy,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final centers = [
      Offset(size.width * 0.88, size.height * 0.08),
      Offset(size.width * 0.05, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.85),
    ];
    for (final center in centers) {
      for (int r = 20; r <= 160; r += 20) {
        canvas.drawCircle(center, r.toDouble(), paint);
      }
      final sp = Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(
          center,
          Offset(center.dx + math.cos(a) * 160,
              center.dy + math.sin(a) * 160),
          sp,
        );
      }
    }
    final lp = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), lp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}