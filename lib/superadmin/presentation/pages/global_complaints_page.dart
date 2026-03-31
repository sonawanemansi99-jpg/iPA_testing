import 'package:audioplayers/audioplayers.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/presentation/screens/complain_details.dart';
import 'package:corporator_app/features/complaints/presentation/screens/edit_complaint_status.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlobalComplaintsPage extends StatefulWidget {
  const GlobalComplaintsPage({Key? key}) : super(key: key);

  @override
  State<GlobalComplaintsPage> createState() => _GlobalComplaintsPageState();
}

class _GlobalComplaintsPageState extends State<GlobalComplaintsPage> with TickerProviderStateMixin {
  final SuperAdminService _superAdminServices = SuperAdminService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  List<dynamic> _allComplaints = [];
  List<dynamic> _filteredComplaints = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _statusFilter = "all";

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // Theme Colors
  static const saffron = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const indiaGreen = Color(0xFF138808);

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
    _fetchGlobalComplaints();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchGlobalComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await _superAdminServices.getAllGlobalComplaints();
      setState(() {
        _allComplaints = data;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredComplaints = _allComplaints.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        final cleanStatus = status.replaceAll(' ', '_');
        final cleanFilter = _statusFilter.replaceAll(' ', '_');
        final matchesStatus = _statusFilter == 'all' || cleanStatus == cleanFilter;

        final citizenName = (c['citizenName'] ?? c['name'] ?? '').toLowerCase();
        final adminName = (c['adminName'] ?? '').toLowerCase();
        final complaintId = (c['id']?.toString() ?? c['complaintId']?.toString() ?? '').toLowerCase();
        
        final searchLower = _searchQuery.toLowerCase();
        final matchesSearch = _searchQuery.isEmpty || 
                              citizenName.contains(searchLower) || 
                              adminName.contains(searchLower) || 
                              complaintId.contains(searchLower);

        return matchesStatus && matchesSearch;
      }).toList();
    });
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
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Audio Error: $e")));
        }
      },
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: isPlaying ? [indiaGreen, Colors.green] : [saffron, deepSaffron]),
          boxShadow: [BoxShadow(color: (isPlaying ? indiaGreen : saffron).withOpacity(0.4), blurRadius: 8)],
        ),
        child: Icon(isPlaying ? Icons.stop : Icons.mic, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulseAnim = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return MainScaffold(
      title: "Global Complaints",
      floatingActionButton: ScaleTransition(
        scale: _isLoading ? pulseAnim : const AlwaysStoppedAnimation(1.0),
        child: FloatingActionButton(
          onPressed: _fetchGlobalComplaints,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [saffron, deepSaffron], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: saffron.withOpacity(0.55), blurRadius: 16, spreadRadius: 2)],
              border: Border.all(color: gold, width: 2),
            ),
            child: _isLoading
                ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.refresh, color: Colors.white, size: 26),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [darkNavy, navyBlue, Color(0xFF003A8C)], stops: [0.0, 0.4, 1.0]),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron]))),
                
                // ── Global Search Bar ──
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search by ID, Citizen, or Admin...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: gold),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                _buildStatusFilterRow(),
                
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: gold))
                    : _filteredComplaints.isEmpty
                        ? const Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.inbox_outlined, color: Colors.white24, size: 64),
                              SizedBox(height: 16),
                              Text("कोई शिकायत नहीं मिली", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w700)),
                              SizedBox(height: 4),
                              Text("No complaints found", style: TextStyle(color: Colors.white30, fontSize: 13)),
                            ]),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filteredComplaints.length,
                            itemBuilder: (_, i) => _buildComplaintCard(_filteredComplaints[i], i),
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                  setState(() { _statusFilter = opt['value']!; _applyFilters(); });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: selected ? LinearGradient(colors: [color, color.withOpacity(0.7)]) : null,
                    color: selected ? null : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? color : Colors.white.withOpacity(0.2), width: selected ? 1.5 : 1),
                    boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))] : [],
                  ),
                  child: Row(
                    children: [
                      Icon(_statusIcon(opt['value']!), color: selected ? Colors.white : Colors.white60, size: 14),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt['hindi']!, style: TextStyle(color: selected ? Colors.white70 : Colors.white38, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          Text(opt['label']!, style: TextStyle(color: selected ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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

  Widget _buildComplaintCard(Map<String, dynamic> complaint, int index) {
    final status = complaint['status']?.toString() ?? 'PENDING';
    final id = complaint['id']?.toString() ?? complaint['complaintId']?.toString() ?? 'N/A';
    final name = complaint['citizenName'] ?? complaint['name'] ?? 'Unknown';
    final adminName = complaint['adminName'] ?? 'SYSTEM';
    final zoneName = complaint['zoneName'] ?? 'Unknown Zone';
    final title = complaint['title'] ?? 'Complaint';
    
    final citizenImages = List<String>.from(complaint['evidenceImageUrls'] ?? []);
    final adminImages = complaint.containsKey('resolutionImageUrl') && complaint['resolutionImageUrl'] != null ? [complaint['resolutionImageUrl'].toString()] : <String>[];
    final citizenVoiceNote = complaint['descriptionVoiceNoteUrl'] ?? '';

    Color statusColor = _statusColor(status);
    final bool hasVoice = citizenVoiceNote.isNotEmpty;
    final bool isTerminal = status.toUpperCase() == 'COMPLETED' || status.toUpperCase() == 'UNRESOLVED';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComplainDetails(complaintMap: complaint))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: warmWhite,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
                    BoxShadow(color: statusColor.withOpacity(0.12), blurRadius: 10, spreadRadius: 1),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: navyBlue, borderRadius: BorderRadius.circular(6)),
                            child: Text("#${index + 1}", style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(id, style: const TextStyle(color: darkNavy, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.5))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(status), color: statusColor, size: 12),
                                const SizedBox(width: 4),
                                Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [statusColor.withOpacity(0.6), Colors.transparent]))),
                      const SizedBox(height: 10),
                      Text(title, style: const TextStyle(color: darkNavy, fontWeight: FontWeight.w800, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      
                      // ── Global Info Overlay ──
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _infoTile(Icons.admin_panel_settings, "Admin", adminName),
                                const SizedBox(height: 8),
                                _infoTile(Icons.map, "Zone", zoneName),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _infoTile(Icons.person_outline, "Citizen", name),
                                const SizedBox(height: 8),
                                _infoTile(Icons.photo_library, "Evidences", "${citizenImages.length} Photos"),
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
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComplainDetails(complaintMap: complaint)));
                                } else {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditComplaintStatus(complaintMap: complaint))).then((_) => _fetchGlobalComplaints());
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: isTerminal ? [indiaGreen, Colors.green.shade700] : [navyBlue, darkNavy]),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: (isTerminal ? indiaGreen : navyBlue).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isTerminal ? Icons.visibility : Icons.edit_outlined, color: isTerminal ? Colors.white : gold, size: 14),
                                    const SizedBox(width: 6),
                                    Text(isTerminal ? "VIEW DETAILS" : "UPDATE STATUS", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
              Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, color: statusColor)),
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
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Color(0xFF888888), fontWeight: FontWeight.w700, letterSpacing: 1)),
              Text(value, style: const TextStyle(fontSize: 13, color: darkNavy, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
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
    final p = Paint()..color = Colors.white.withOpacity(0.025)..style = PaintingStyle.stroke..strokeWidth = 1;
    final centers = [Offset(size.width * 0.88, size.height * 0.06), Offset(size.width * 0.05, size.height * 0.45), Offset(size.width * 0.7, size.height * 0.88)];
    for (final c in centers) {
      for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
      final sp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(c, Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160), sp);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}