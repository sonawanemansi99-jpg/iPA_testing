import 'package:audioplayers/audioplayers.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/auth/presentation/login.dart';
import 'package:corporator_app/features/complaints/presentation/screens/complain_details.dart';
import 'package:corporator_app/features/complaints/presentation/screens/edit_complaint_status.dart';
import 'package:corporator_app/services/complaint_service.dart';
import 'package:corporator_app/services/zone_service.dart';
import 'package:corporator_app/services/zone_sevak_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ZoneSevakComplaintsPage extends StatefulWidget {
  const ZoneSevakComplaintsPage({super.key});

  @override
  State<ZoneSevakComplaintsPage> createState() =>
      _ZoneSevakComplaintsPageState();
}

class _ZoneSevakComplaintsPageState extends State<ZoneSevakComplaintsPage>
    with TickerProviderStateMixin {
  final ComplaintService _complaintService = ComplaintService();
  final ZoneService _zoneService = ZoneService();
  final ZoneSevakService _sevakService = ZoneSevakService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  // ── State Variables ──
  List<Map<String, dynamic>> allComplaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];

  // ── Filters & Profile ──
  String _statusFilter = "all";
  String _zoneFilter = "all";
  List<Map<String, String>> _availableZones = [
    {'value': 'all', 'label': 'ALL MY ZONES'},
  ];

  bool isLoading = true;
  String? _error;
  
  // Profile Data
  String? sevakName;
  String? sevakEmail;
  String? sevakMobile;
  String? sevakPhotoUrl;
  bool _isActive = true; 

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // ── Brand Colors ──
  static const Color saffron = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00);
  static const Color gold = Color(0xFFFFD700);
  static const Color navyBlue = Color(0xFF002868);
  static const Color darkNavy = Color(0xFF001A45);
  static const Color warmWhite = Color(0xFFFFFDF7);
  static const Color indiaGreen = Color(0xFF138808);

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'ALL', 'hindi': 'सभी'},
    {'value': 'pending', 'label': 'PENDING', 'hindi': 'लंबित'},
    {'value': 'in_progress', 'label': 'IN PROGRESS', 'hindi': 'प्रगति में'},
    {'value': 'completed', 'label': 'COMPLETED', 'hindi': 'पूर्ण'},
    {'value': 'deferred', 'label': 'DEFERRED', 'hindi': 'स्थगित'},
    {'value': 'unresolved', 'label': 'UNRESOLVED', 'hindi': 'अनसुलझा'},
  ];

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

  @override
  void dispose() {
    _pulseController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final storedName = await _storage.read(key: 'name') ?? 'Sevak';

      // Fetch Profile to check isActive status and load details
      Map<String, dynamic>? profile;
      try {
        profile = await _sevakService.getZoneSevakProfile();
      } catch (e) {
        debugPrint("Could not fetch profile: $e");
      }

      final bool activeStatus = profile?['isActive'] ?? true;
      
      // Populate profile data
      sevakName = profile?['name'] ?? storedName;
      sevakEmail = profile?['email'] ?? 'No Email';
      sevakMobile = profile?['mobileNumber'] ?? 'No Mobile Number';
      sevakPhotoUrl = profile?['livePhotoUrl'] ?? '';

      if (activeStatus) {
        // Only fetch complaints and zones if the account is active
        final results = await Future.wait([
          _complaintService.fetchComplaints(),
          _zoneService.fetchMyZones(),
        ]);

        final complaintsData = results[0];
        final zonesData = results[1];

        final List<Map<String, String>> builtZones = [
          {'value': 'all', 'label': 'ALL MY ZONES'},
        ];
        for (var z in zonesData) {
          builtZones.add({
            'value': z['name'].toString(),
            'label': z['name'].toString().toUpperCase(),
          });
        }

        if (mounted) {
          setState(() {
            _isActive = true;
            allComplaints = complaintsData;
            _availableZones = builtZones;

            if (!builtZones.any((z) => z['value'] == _zoneFilter)) {
              _zoneFilter = 'all';
            }

            _applyFilters();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isActive = false;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredComplaints = allComplaints.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        final zone = (c['zoneName'] ?? '').toString();

        final cleanStatus = status.replaceAll(' ', '_');
        final cleanFilter = _statusFilter.replaceAll(' ', '_');

        final matchesStatus =
            _statusFilter == 'all' || cleanStatus == cleanFilter;
        final matchesZone = _zoneFilter == 'all' || zone == _zoneFilter;

        return matchesStatus && matchesZone;
      }).toList();
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  void _logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'completed': return indiaGreen;
      case 'in_progress': return saffron;
      case 'deferred': return Colors.blueGrey;
      case 'unresolved': return Colors.brown.shade600;
      case 'pending': default: return const Color(0xFFCC3300);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'completed': return Icons.check_circle_outline;
      case 'in_progress': return Icons.timelapse;
      case 'deferred': return Icons.schedule;
      case 'unresolved': return Icons.warning_amber_rounded;
      case 'pending': default: return Icons.pending_outlined;
    }
  }

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
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Audio Error: $e")));
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isPlaying ? [indiaGreen, Colors.green] : [saffron, deepSaffron],
          ),
          boxShadow: [
            BoxShadow(
              color: (isPlaying ? indiaGreen : saffron).withOpacity(0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(isPlaying ? Icons.stop : Icons.mic, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulseAnim =
        _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return MainScaffold(
      title: "Sevak Dashboard",
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
            Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [saffron, gold, saffron]),
                  ),
                ),
                
                // ── Dynamic Profile Card (Replaces old header) ──
                _buildProfileCard(pulseAnim, _isActive),

                if (_isActive) ...[
                  if (!isLoading && _error == null) ...[
                    _buildZoneDropdown(),
                    _buildStatusFilterRow(),
                  ],
                  Expanded(child: _buildComplaintList()),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: _buildSuspendedNotice(),
                  ),
                  const Spacer(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── REPLACED _buildHeader with _buildProfileCard ──
  Widget _buildProfileCard(Animation<double> pulse, bool isActive) {
    final name = sevakName ?? 'Loading...';
    final email = sevakEmail ?? 'Loading...';
    final mobileNo = sevakMobile ?? 'Loading...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: ScaleTransition(
        scale: pulse,
        child: Container(
          decoration: BoxDecoration(
            color: warmWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isActive ? gold : Colors.red).withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Gold/Red header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive ? [darkNavy, navyBlue] : [Colors.red[900]!, Colors.red[700]!]
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isActive ? "ZONE SEVAK PROFILE" : "ACCOUNT SUSPENDED",
                        style: const TextStyle(
                          color: gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, gold],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with ring based on status
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? gold : Colors.red,
                            width: 2,
                          ),
                          image: sevakPhotoUrl != null && sevakPhotoUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(sevakPhotoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: sevakPhotoUrl == null || sevakPhotoUrl!.isEmpty
                              ? RadialGradient(
                                  colors: isActive ? [gold, saffron] : [Colors.red, Colors.red[900]!],
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: (isActive ? gold : Colors.red).withOpacity(0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: sevakPhotoUrl == null || sevakPhotoUrl!.isEmpty
                            ? const Icon(Icons.engineering, color: darkNavy, size: 32)
                            : null,
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name with shimmer-style gradient
                            ShaderMask(
                              shaderCallback: (b) => LinearGradient(
                                colors: isActive ? [darkNavy, navyBlue] : [Colors.red[900]!, Colors.red],
                              ).createShader(b),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _profileDetail(Icons.email_outlined, email),
                            const SizedBox(height: 4),
                            _profileDetail(Icons.phone_outlined, mobileNo),
                            const SizedBox(height: 8),
                            
                            // Rank badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isActive ? [saffron, deepSaffron] : [Colors.red, Colors.red[800]!],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? "✦  ZONE SEVAK" : "✖  SUSPENDED",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // ── STYLED LOGOUT ICON BUTTON ──
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.redAccent, size: 26),
                          onPressed: _logout,
                          tooltip: "Secure Logout",
                          splashRadius: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileDetail(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: saffron, size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF444444),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSuspendedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.red[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_person, color: Colors.redAccent, size: 52),
          const SizedBox(height: 16),
          const Text(
            "ACCESS REVOKED",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Your Sevak privileges have been suspended by your Corporator. You can no longer view or manage assigned complaints.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneDropdown() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withOpacity(0.3), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _zoneFilter,
          isExpanded: true,
          dropdownColor: navyBlue,
          icon: const Icon(Icons.arrow_drop_down_circle, color: gold, size: 20),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          items: _availableZones.map((zone) {
            return DropdownMenuItem<String>(
              value: zone['value'],
              child: Row(
                children: [
                  Icon(
                    zone['value'] == 'all' ? Icons.map : Icons.location_on,
                    color: saffron,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(zone['label']!),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _zoneFilter = newValue;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((opt) {
            final selected = _statusFilter == opt['value'];
            final color = _statusColor(opt['value']!);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _statusFilter = opt['value']!;
                    _applyFilters();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          )
                        : null,
                    color: selected ? null : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? color : Colors.white.withOpacity(0.2),
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
                        _statusIcon(opt['value']!),
                        color: selected ? Colors.white : Colors.white60,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['hindi']!,
                            style: TextStyle(
                              color: selected ? Colors.white70 : Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            opt['label']!,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white60,
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
    if (isLoading)
      return const Center(child: CircularProgressIndicator(color: gold));

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 52),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
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
              "No complaints found in your zones",
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: filteredComplaints.length,
      itemBuilder: (_, i) => _buildComplaintCard(filteredComplaints[i], i),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint, int index) {
    final status = complaint['status']?.toString() ?? 'PENDING';
    final id =
        complaint['id']?.toString() ??
        complaint['complaintId']?.toString() ??
        'N/A';
    final name = complaint['citizenName'] ?? complaint['name'] ?? 'Unknown';
    final zoneName = complaint['zoneName'] ?? 'Unknown Zone';
    final areaName = complaint['areaName'] ?? 'Unknown Area';
    final title = complaint['title'] ?? 'Complaint';
    final mobileNo =
        complaint['mobileNumber'] ?? complaint['mobileNo'] ?? 'N/A';

    final citizenImages = List<String>.from(
      complaint['evidenceImageUrls'] ?? [],
    );
    final adminImages =
        complaint.containsKey('resolutionImageUrl') &&
            complaint['resolutionImageUrl'] != null
        ? [complaint['resolutionImageUrl'].toString()]
        : <String>[];

    final citizenVoiceNote = complaint['descriptionVoiceNoteUrl'] ?? '';

    Color statusColor = _statusColor(status);
    final bool hasVoice = citizenVoiceNote.isNotEmpty;
    final bool isTerminal =
        status.toUpperCase() == 'COMPLETED' ||
        status.toUpperCase() == 'UNRESOLVED';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ComplainDetails(complaintMap: complaint),
          ),
        ),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon(status),
                                  color: statusColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      Text(
                        title,
                        style: const TextStyle(
                          color: darkNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _infoTile(Icons.person_outline, "Name", name),
                                const SizedBox(height: 8),
                                _infoTile(Icons.map, "Zone", zoneName),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _infoTile(
                                  Icons.phone_outlined,
                                  "Mobile",
                                  mobileNo,
                                ),
                                const SizedBox(height: 8),
                                _infoTile(Icons.location_on, "Area", areaName),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (isTerminal) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ComplainDetails(
                                        complaintMap: complaint,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) => EditComplaintStatus(
                                            complaintMap: complaint,
                                          ),
                                        ),
                                      )
                                      .then((_) => _refresh());
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isTerminal
                                        ? [indiaGreen, Colors.green.shade700]
                                        : [navyBlue, darkNavy],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isTerminal ? indiaGreen : navyBlue)
                                              .withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isTerminal
                                          ? Icons.visibility
                                          : Icons.edit_outlined,
                                      color: isTerminal ? Colors.white : gold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isTerminal
                                          ? "VIEW DETAILS"
                                          : "UPDATE STATUS",
                                      style: const TextStyle(
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showImagesDialog(
                                context,
                                citizenImages,
                                adminImages,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [saffron, deepSaffron],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: saffron.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
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
                          if (hasVoice) ...[
                            const SizedBox(width: 8),
                            _voicePlayer(citizenVoiceNote, id),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
                        _sectionLabel("नागरिक द्वारा अपलोड", "Citizen Images"),
                        const SizedBox(height: 10),
                        ...citizenImages.map(imageTile),
                        const SizedBox(height: 12),
                      ],
                      if (adminImages.isNotEmpty) ...[
                        _sectionLabel("प्रशासन द्वारा अपलोड", "Admin Images"),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
}

class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final centers = [
      Offset(size.width * 0.88, size.height * 0.08),
      Offset(size.width * 0.05, size.height * 0.5),
      Offset(size.width * 0.75, size.height * 0.85),
    ];
    for (final c in centers) {
      for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
      final sp = Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(
          c,
          Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160),
          sp,
        );
      }
    }
    final lp = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40)
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}