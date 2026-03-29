import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/domain/model/complaint_model.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class ComplainDetails extends StatefulWidget {
  final ComplaintModel complaint;
  const ComplainDetails({super.key, required this.complaint});

  @override
  State<ComplainDetails> createState() => _ComplainDetailsState();
}

class _ComplainDetailsState extends State<ComplainDetails> {
  // ── Brand Colors ──
  static const saffron     = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold        = Color(0xFFFFD700);
  static const navyBlue    = Color(0xFF002868);
  static const darkNavy    = Color(0xFF001A45);
  static const warmWhite   = Color(0xFFFFFDF7);
  static const indiaGreen  = Color(0xFF138808);

  // ── Audio players (one per voice note slot) ──
  final AudioPlayer _citizenPlayer = AudioPlayer();
  final AudioPlayer _adminPlayer   = AudioPlayer();

  PlayerState _citizenState = PlayerState.stopped;
  PlayerState _adminState   = PlayerState.stopped;

  Duration _citizenDuration = Duration.zero;
  Duration _citizenPosition = Duration.zero;
  Duration _adminDuration   = Duration.zero;
  Duration _adminPosition   = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupPlayer(
      player:       _citizenPlayer,
      onState:      (s) => setState(() => _citizenState = s),
      onDuration:   (d) => setState(() => _citizenDuration = d),
      onPosition:   (p) => setState(() => _citizenPosition = p),
    );
    _setupPlayer(
      player:       _adminPlayer,
      onState:      (s) => setState(() => _adminState = s),
      onDuration:   (d) => setState(() => _adminDuration = d),
      onPosition:   (p) => setState(() => _adminPosition = p),
    );
  }

  void _setupPlayer({
    required AudioPlayer player,
    required void Function(PlayerState) onState,
    required void Function(Duration) onDuration,
    required void Function(Duration) onPosition,
  }) {
    player.onPlayerStateChanged.listen(onState);
    player.onDurationChanged.listen(onDuration);
    player.onPositionChanged.listen(onPosition);
  }

  @override
  void dispose() {
    _citizenPlayer.dispose();
    _adminPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(AudioPlayer player, String url) async {
    if (player.state == PlayerState.playing) {
      await player.pause();
    } else {
      await player.play(UrlSource(url));
    }
  }

  Future<void> _seek(AudioPlayer player, double value, Duration total) async {
    final pos = Duration(milliseconds: (value * total.inMilliseconds).toInt());
    await player.seek(pos);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // ── Status helpers ──
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'complete':    return indiaGreen;
      case 'in progress': return saffron;
      default:            return const Color(0xFFCC3300);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'complete':    return Icons.check_circle_outline;
      case 'in progress': return Icons.timelapse;
      default:            return Icons.hourglass_top;
    }
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
              panEnabled: true, minScale: 1, maxScale: 5,
              child: Image.network(imageUrl, fit: BoxFit.contain,
                loadingBuilder: (_, child, prog) =>
                    prog == null ? child : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white, size: 50)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;

    return MainScaffold(
      title: "Complaint Details",
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkNavy, navyBlue, Color(0xFF003A8C)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),

          Column(children: [
            Container(height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [saffron, gold, saffron]))),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(children: [

                  // ── Status Banner ──
                  _buildStatusBanner(c),
                  const SizedBox(height: 16),

                  // ── Citizen Info ──
                  _buildSectionCard(
                    title: "CITIZEN INFORMATION",
                    icon: Icons.person_outline,
                    children: [
                      _infoRow(Icons.badge_outlined,  "Complaint ID", c.complaintId),
                      _divider(),
                      _infoRow(Icons.person_outline,  "Name",         c.name),
                      _divider(),
                      _infoRow(Icons.phone_outlined,  "Mobile No.",   c.mobileNo),
                      _divider(),
                      _infoRow(Icons.email_outlined,  "Email",        c.email),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Complaint Details ──
                  _buildSectionCard(
                    title: "COMPLAINT DETAILS",
                    icon: Icons.article_outlined,
                    children: [
                      _infoRow(Icons.map_outlined, "Zone", c.zoneName),
                      _divider(),
                      c.description.trim().isEmpty
                          ? _emptyField("No description provided")
                          : _descriptionBox(c.description),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Action Taken ──
                  if (c.actionTaken.isNotEmpty) ...[
                    _buildSectionCard(
                      title: "ACTION TAKEN",
                      icon: Icons.build_outlined,
                      children: [_descriptionBox(c.actionTaken)],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Citizen Voice Note ──
                  _buildSectionCard(
                    title: "CITIZEN VOICE NOTE",
                    icon: Icons.mic_outlined,
                    children: [
                      c.citizenVoiceNote != null && c.citizenVoiceNote!.isNotEmpty
                          ? _voiceNotePlayer(
                              url:      c.citizenVoiceNote!,
                              player:   _citizenPlayer,
                              state:    _citizenState,
                              position: _citizenPosition,
                              duration: _citizenDuration,
                              accentColor: saffron,
                            )
                          : _emptyField("No voice note uploaded by citizen"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Admin Voice Note ──
                  _buildSectionCard(
                    title: "ADMIN VOICE NOTE",
                    icon: Icons.record_voice_over_outlined,
                    children: [
                      c.adminVoiceNote != null && c.adminVoiceNote!.isNotEmpty
                          ? _voiceNotePlayer(
                              url:      c.adminVoiceNote!,
                              player:   _adminPlayer,
                              state:    _adminState,
                              position: _adminPosition,
                              duration: _adminDuration,
                              accentColor: navyBlue,
                            )
                          : _emptyField("No voice note uploaded by admin"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Citizen Images ──
                  _buildSectionCard(
                    title: "CITIZEN IMAGES",
                    icon: Icons.photo_library_outlined,
                    children: [
                      c.citizenImages.isEmpty
                          ? _emptyField("No images uploaded by citizen")
                          : _imageStrip(context, c.citizenImages),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Admin Images ──
                  _buildSectionCard(
                    title: "ADMIN IMAGES",
                    icon: Icons.admin_panel_settings_outlined,
                    children: [
                      c.adminImages.isEmpty
                          ? _emptyField("No images uploaded by admin")
                          : _imageStrip(context, c.adminImages),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Footer ──
                  Row(children: [
                    Expanded(child: Container(height: 3, color: saffron)),
                    Expanded(child: Container(height: 3, color: warmWhite)),
                    Expanded(child: Container(height: 3, color: indiaGreen)),
                  ]),
                  const SizedBox(height: 10),
                  Text("© 2025 Corporator Portal. All Rights Reserved.",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Voice note player widget ──
  Widget _voiceNotePlayer({
    required String url,
    required AudioPlayer player,
    required PlayerState state,
    required Duration position,
    required Duration duration,
    required Color accentColor,
  }) {
    final isPlaying = state == PlayerState.playing;
    final progress  = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(children: [
        Row(children: [
          // Play / Pause button
          GestureDetector(
            onTap: () => _togglePlay(player, url),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 10)],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 28,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Waveform-style progress
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SliderTheme(
                data: SliderThemeData(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  trackHeight: 4,
                  activeTrackColor: accentColor,
                  inactiveTrackColor: accentColor.withOpacity(0.2),
                  thumbColor: accentColor,
                  overlayColor: accentColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (v) => _seek(player, v, duration),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position),
                      style: TextStyle(color: accentColor, fontSize: 11,
                        fontWeight: FontWeight.w700)),
                    Text(_formatDuration(duration),
                      style: const TextStyle(color: Color(0xFF888888),
                        fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ]),
          ),
        ]),

        // Animated sound wave bars when playing
        if (isPlaying) ...[
          const SizedBox(height: 10),
          _buildWaveBars(accentColor),
        ],
      ]),
    );
  }

  // ── Animated wave bars ──
  Widget _buildWaveBars(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(16, (i) {
        final height = 6.0 + (math.sin(i * 0.8) * 10).abs();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6 + (i % 3) * 0.13),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  // ── Status banner ──
  Widget _buildStatusBanner(ComplaintModel c) {
    final color = _statusColor(c.status);
    final icon  = _statusIcon(c.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("COMPLAINT STATUS",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(c.status.toUpperCase(),
            style: TextStyle(color: color, fontSize: 20,
              fontWeight: FontWeight.w900, letterSpacing: 2)),
        ])),
        statusBadge(c.status),
      ]),
    );
  }

  // ── Section card ──
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: saffron.withOpacity(0.08), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [darkNavy, navyBlue]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Icon(icon, color: gold, size: 16),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: gold, fontSize: 12,
              fontWeight: FontWeight.w900, letterSpacing: 2.5)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: saffron, size: 16),
        const SizedBox(width: 10),
        SizedBox(width: 90,
          child: Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: Color(0xFF888888),
              fontWeight: FontWeight.w700, letterSpacing: 1))),
        const Text("  :  ", style: TextStyle(color: Color(0xFFAAAAAA))),
        Expanded(child: Text(value.isEmpty ? "—" : value,
          style: TextStyle(fontSize: 14,
            color: value.isEmpty ? Colors.grey.shade400 : darkNavy,
            fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _descriptionBox(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.notes_outlined, color: saffron, size: 16),
          SizedBox(width: 10),
          Text("DESCRIPTION", style: TextStyle(fontSize: 10, color: Color(0xFF888888),
            fontWeight: FontWeight.w700, letterSpacing: 1)),
        ]),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5EF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(text, style: const TextStyle(fontSize: 14, color: darkNavy,
            fontWeight: FontWeight.w500, height: 1.5)),
        ),
      ]),
    );
  }

  // ── Empty field placeholder ──
  Widget _emptyField(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(Icons.info_outline, color: Colors.grey.shade400, size: 16),
        ),
        const SizedBox(width: 10),
        Text(message, style: TextStyle(color: Colors.grey.shade500,
          fontSize: 13, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _divider() => Divider(color: gold.withOpacity(0.15), height: 1, thickness: 1);

  Widget _imageStrip(BuildContext context, List<String> images) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => displayFullImage(context, images[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            width: 110, height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withOpacity(0.5), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(images[i], fit: BoxFit.cover,
                loadingBuilder: (_, child, prog) => prog == null
                    ? child
                    : Container(color: const Color(0xFFF0EEE8),
                        child: const Center(child: CircularProgressIndicator(color: saffron, strokeWidth: 2))),
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF0EEE8),
                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 32))),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.stroke..strokeWidth = 1;
    final centers = [
      Offset(size.width * 0.88, size.height * 0.06),
      Offset(size.width * 0.05, size.height * 0.5),
      Offset(size.width * 0.7,  size.height * 0.88),
    ];
    for (final c in centers) {
      for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
      final sp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(c, Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160), sp);
      }
    }
    final lp = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40)
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }

  @override
  bool shouldRepaint(_) => false;
}