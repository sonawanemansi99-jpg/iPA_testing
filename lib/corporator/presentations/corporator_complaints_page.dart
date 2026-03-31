import 'package:audioplayers/audioplayers.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/presentation/screens/complain_details.dart';
import 'package:corporator_app/features/complaints/presentation/screens/edit_complaint_status.dart';
import 'package:corporator_app/services/complaint_service.dart';
import 'package:corporator_app/services/zone_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CorporatorComplaintsPage extends StatefulWidget {
  final int? adminId;
  const CorporatorComplaintsPage({super.key, this.adminId});

  @override
  State<CorporatorComplaintsPage> createState() => _CorporatorComplaintsPageState();
}

class _CorporatorComplaintsPageState extends State<CorporatorComplaintsPage> with TickerProviderStateMixin {
  final ComplaintService _complaintService = ComplaintService();
  final ZoneService _zoneService = ZoneService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  // ── State Variables ──
  List<Map<String, dynamic>> allComplaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];
  
  // ── Filters ──
  String _statusFilter = "all";
  String _zoneFilter = "all";
  List<Map<String, String>> _availableZones = [{'value': 'all', 'label': 'ALL ZONES'}];

  bool isLoading = true;
  String? _error;
  String? adminName;

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
      final storedName = await _storage.read(key: 'name') ?? 'Admin';

      final results = await Future.wait([
        _complaintService.fetchComplaints(adminId: widget.adminId),
        _zoneService.fetchMyZones(adminId: widget.adminId), 
      ]);

      final complaintsData = results[0];
      final zonesData = results[1];

      final List<Map<String, String>> builtZones = [{'value': 'all', 'label': 'ALL ZONES'}];
      for (var z in zonesData) {
        builtZones.add({
          'value': z['name'].toString(),
          'label': z['name'].toString().toUpperCase(),
        });
      }

      if (mounted) {
        setState(() {
          adminName = storedName;
          allComplaints = complaintsData;
          _availableZones = builtZones;
          
          if (!builtZones.any((z) => z['value'] == _zoneFilter)) {
            _zoneFilter = 'all';
          }
          
          _applyFilters();
          isLoading = false;
        });
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

        final matchesStatus = _statusFilter == 'all' || cleanStatus == cleanFilter;
        final matchesZone = _zoneFilter == 'all' || zone == _zoneFilter;

        return matchesStatus && matchesZone;
      }).toList();
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'completed':
        return indiaGreen;
      case 'in_progress':
        return saffron;
      case 'deferred':
        return Colors.blueGrey;
      case 'unresolved':
        return Colors.brown.shade600;
      case 'pending':
      default:
        return const Color(0xFFCC3300);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.timelapse;
      case 'deferred':
        return Icons.schedule;
      case 'unresolved':
        return Icons.warning_amber_rounded;
      case 'pending':
      default:
        return Icons.pending_outlined;
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
        width: 40,
        height: 40,
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
      title: widget.adminId != null ? "Inspecting Complaints" : "Complaint Inbox", // Clean, modern title
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
              gradient: const LinearGradient(colors: [saffron, deepSaffron], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: saffron.withOpacity(0.55), blurRadius: 16, spreadRadius: 2)],
              border: Border.all(color: gold, width: 2),
            ),
            child: isLoading
                ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
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
                Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron]))),
                _buildHeader(),
                if (!isLoading && _error == null) ...[
                  _buildZoneDropdown(),
                  _buildStatusFilterRow(),
                ],
                Expanded(child: _buildComplaintList()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              boxShadow: [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 12)],
            ),
            child: const Icon(Icons.account_balance, color: darkNavy, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("GRIEVANCE REDRESSAL", style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                const SizedBox(height: 3),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: saffron.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: saffron, width: 1),
            ),
            child: Text(
              "${allComplaints.length}\nTOTAL",
              textAlign: TextAlign.center,
              style: const TextStyle(color: saffron, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, height: 1.2),
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
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
          items: _availableZones.map((zone) {
            return DropdownMenuItem<String>(
              value: zone['value'],
              child: Row(
                children: [
                  Icon(zone['value'] == 'all' ? Icons.map : Icons.location_on, color: saffron, size: 16),
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

  Widget _buildComplaintList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: gold));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 52),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
        ]),
      );
    }
    if (filteredComplaints.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.inbox_outlined, color: Colors.white24, size: 64),
          SizedBox(height: 16),
          Text("कोई शिकायत नहीं मिली", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text("No complaints found", style: TextStyle(color: Colors.white30, fontSize: 13)),
        ]),
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
    final id = complaint['id']?.toString() ?? complaint['complaintId']?.toString() ?? 'N/A';
    final name = complaint['citizenName'] ?? complaint['name'] ?? 'Unknown';
    final zoneName = complaint['zoneName'] ?? 'Unknown Zone';
    final areaName = complaint['areaName'] ?? 'Unknown Area';
    final title = complaint['title'] ?? 'Complaint';
    final mobileNo = complaint['mobileNumber'] ?? complaint['mobileNo'] ?? 'N/A';
    
    final citizenImages = List<String>.from(complaint['evidenceImageUrls'] ?? []);
    final adminImages = complaint.containsKey('resolutionImageUrl') && complaint['resolutionImageUrl'] != null 
                        ? [complaint['resolutionImageUrl'].toString()] 
                        : <String>[];
                        
    final citizenVoiceNote = complaint['descriptionVoiceNoteUrl'] ?? '';

    Color statusColor = _statusColor(status);
    final bool hasVoice = citizenVoiceNote.isNotEmpty;
    
    // ── SMART UX TRIGGER ──
    // Determine if the complaint is in a terminal state
    final bool isTerminal = status.toUpperCase() == 'COMPLETED' || status.toUpperCase() == 'UNRESOLVED';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ComplainDetails(complaintMap: complaint)),
        ),
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
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
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
                                _infoTile(Icons.phone_outlined, "Mobile", mobileNo),
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
                          // ── DYNAMIC BUTTON LOGIC ──
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (isTerminal) {
                                  // If closed, open the detailed read-only view
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ComplainDetails(complaintMap: complaint)),
                                  );
                                } else {
                                  // If open, go to the update screen
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => EditComplaintStatus(complaintMap: complaint)),
                                  ).then((_) => _refresh());
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isTerminal ? [indiaGreen, Colors.green.shade700] : [navyBlue, darkNavy]
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isTerminal ? indiaGreen : navyBlue).withOpacity(0.4), 
                                      blurRadius: 8, 
                                      offset: const Offset(0, 3)
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isTerminal ? Icons.visibility : Icons.edit_outlined, color: isTerminal ? Colors.white : gold, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      isTerminal ? "VIEW DETAILS" : "UPDATE STATUS", 
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showImagesDialog(context, citizenImages, adminImages),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [saffron, deepSaffron]),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: saffron.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.photo_library_outlined, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text("PHOTOS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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

  // ── Modals & Helpers ──
  void displayFullImage(BuildContext context, String imageUrl) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: Center(child: InteractiveViewer(panEnabled: true, minScale: 1, maxScale: 5, child: Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 50)))))));
  }

  Widget imageTile(String url) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: GestureDetector(onTap: () => displayFullImage(context, url), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, fit: BoxFit.cover, height: 150, width: double.infinity))));
  }

  void showImagesDialog(BuildContext context, List<String> citizenImages, List<String> adminImages) {
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: Container(decoration: BoxDecoration(color: warmWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: gold.withOpacity(0.5), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24)]), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkNavy, navyBlue]), borderRadius: BorderRadius.vertical(top: Radius.circular(18))), child: const Text("COMPLAINT IMAGES", textAlign: TextAlign.center, style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 3))), Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (citizenImages.isNotEmpty) ...[_sectionLabel("नागरिक द्वारा अपलोड", "Citizen Images"), const SizedBox(height: 10), ...citizenImages.map(imageTile), const SizedBox(height: 12)], if (adminImages.isNotEmpty) ...[_sectionLabel("प्रशासन द्वारा अपलोड", "Admin Images"), const SizedBox(height: 10), ...adminImages.map(imageTile)], const SizedBox(height: 16), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: saffron, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2))))])))],))));
  }

  Widget _sectionLabel(String hindi, String english) {
    return Row(children: [Container(width: 4, height: 20, color: saffron, margin: const EdgeInsets.only(right: 10)), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(hindi, style: const TextStyle(fontSize: 11, color: saffron, fontWeight: FontWeight.w700, letterSpacing: 1)), Text(english, style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w900))])]);
  }
}

class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.025)..style = PaintingStyle.stroke..strokeWidth = 1;
    final centers = [Offset(size.width * 0.88, size.height * 0.08), Offset(size.width * 0.05, size.height * 0.5), Offset(size.width * 0.75, size.height * 0.85)];
    for (final center in centers) {
      for (int r = 20; r <= 160; r += 20) canvas.drawCircle(center, r.toDouble(), paint);
      final sp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(center, Offset(center.dx + math.cos(a) * 160, center.dy + math.sin(a) * 160), sp);
      }
    }
    final lp = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40) canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}