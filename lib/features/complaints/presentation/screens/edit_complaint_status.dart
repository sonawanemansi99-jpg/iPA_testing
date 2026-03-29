import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corporator_app/core/widgets/app_text_input_field.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/domain/model/complaint_model.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/complaint_image_section.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/image_displayer.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/status_badge.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

class EditComplaintStatus extends StatefulWidget {
  final ComplaintModel complaint;
  const EditComplaintStatus({super.key, required this.complaint});
  @override
  State<EditComplaintStatus> createState() => _EditComplaintStatusState();
}

class _EditComplaintStatusState extends State<EditComplaintStatus> {
  late String selectedStatus;
  final actionDescriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isSubmitting = false;

  // ── Voice note ──
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedPath;   // local file path after recording
  String? _uploadedVoiceUrl; // URL after uploading to Storage
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  static const saffron    = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold       = Color(0xFFFFD700);
  static const navyBlue   = Color(0xFF002868);
  static const darkNavy   = Color(0xFF001A45);
  static const warmWhite  = Color(0xFFFFFDF7);
  static const indiaGreen = Color(0xFF138808);

  bool get isCompleted => widget.complaint.status == "complete";

  // Whether the admin has provided *something* (text OR voice)
  bool get _hasActionInput =>
      actionDescriptionController.text.trim().isNotEmpty ||
      _recordedPath != null;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.complaint.status;
    if (isCompleted) {
      actionDescriptionController.text = widget.complaint.actionTaken;
    }
    actionDescriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    actionDescriptionController.dispose();
    _recorder.dispose();
    _player.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  List<DropdownMenuItem<String>> getStatusOptions() {
    if (widget.complaint.status == "pending")
      return const [
        DropdownMenuItem(value: "pending",      child: Text("Pending")),
        DropdownMenuItem(value: "in progress",  child: Text("In Progress")),
      ];
    if (widget.complaint.status == "in progress")
      return const [
        DropdownMenuItem(value: "in progress",  child: Text("In Progress")),
        DropdownMenuItem(value: "complete",     child: Text("Complete")),
      ];
    return const [];
  }

  // ── Recording helpers ──
  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showSnack("Microphone permission denied", isError: true);
        return;
      }

      // Use app documents directory — more reliable than temp on Android
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'admin_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = '${dir.path}/$fileName';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
        _recordedPath = null;
        _uploadedVoiceUrl = null;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordDuration += const Duration(seconds: 1));
      });
    } catch (e) {
      _showSnack("Could not start recording: $e", isError: true);
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    try {
      final path = await _recorder.stop();
      if (path == null) {
        _showSnack("Recording failed: no file was saved", isError: true);
        setState(() => _isRecording = false);
        return;
      }
      // Verify file actually exists on disk
      final file = File(path);
      if (!await file.exists()) {
        _showSnack("Recording file not found at: $path", isError: true);
        setState(() => _isRecording = false);
        return;
      }
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
    } catch (e) {
      setState(() => _isRecording = false);
      _showSnack("Could not stop recording: $e", isError: true);
    }
  }

  void _deleteRecording() {
    if (_recordedPath != null) {
      try { File(_recordedPath!).deleteSync(); } catch (_) {}
    }
    setState(() {
      _recordedPath = null;
      _uploadedVoiceUrl = null;
      _isPlaying = false;
      _recordDuration = Duration.zero;
    });
    _player.stop();
  }

  Future<void> _togglePlay() async {
    if (_recordedPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.play(DeviceFileSource(_recordedPath!));
      setState(() => _isPlaying = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  /// Uploads the recorded file to Firebase Storage and returns the download URL.
  

Future<String> _uploadVoiceNote() async {
  if (_recordedPath == null) {
    throw Exception("No recording found");
  }

  final file = File(_recordedPath!);
  if (!await file.exists()) {
    throw Exception("Voice note file missing");
  }

  const cloudName = "dq18qyvol";
  const uploadPreset = "flutter_unsigned";

  final uri = Uri.parse(
    "https://api.cloudinary.com/v1_1/$cloudName/video/upload",
  );

  final request = http.MultipartRequest("POST", uri);

  request.fields["upload_preset"] = uploadPreset;

  request.files.add(
    await http.MultipartFile.fromPath(
      "file",
      file.path,
      filename: "admin_voice_${DateTime.now().millisecondsSinceEpoch}.m4a",
    ),
  );

  final response = await request.send();
  final responseData = await response.stream.bytesToString();
  final jsonData = jsonDecode(responseData);

  if (response.statusCode == 200) {
    return jsonData["secure_url"];
  } else {
    throw Exception("Cloudinary upload failed: $responseData");
  }
}


  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Submit ──
  Future<void> updateComplaint() async {
    // Validate: if completing, need text OR voice
    if (selectedStatus == "complete") {
      if (!_hasActionInput) {
        _showSnack(
          "Please add a description or record a voice note",
          isError: true,
        );
        return;
      }
      // If text is provided, validate via form
      if (actionDescriptionController.text.trim().isNotEmpty) {
        if (!formKey.currentState!.validate()) return;
      }
    }

    try {
      setState(() => isSubmitting = true);

      // Upload voice note if present
      String? voiceUrl;
      if (_recordedPath != null && selectedStatus == "complete") {
        voiceUrl = await _uploadVoiceNote();
      }

      final q = await firestore
          .collection("complaints")
          .where("complaintId", isEqualTo: widget.complaint.complaintId)
          .limit(1)
          .get();
      if (q.docs.isEmpty) throw Exception("Complaint not found");

      await firestore.collection("complaints").doc(q.docs.first.id).update({
        "status": selectedStatus,
        if (selectedStatus == "complete") ...{
          "actionTaken": actionDescriptionController.text.trim(),
          "actionTakenAt": FieldValue.serverTimestamp(),
          if (voiceUrl != null) "adminVoiceNote": voiceUrl,
        },
      });

      if (!mounted) return;
      _showSnack("स्थिति सफलतापूर्वक अपडेट की गई!", isError: false);
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : indiaGreen,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void displayImagesDialog(List<String> images, String title) {
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
                child: Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                    children: [
                      if (images.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "कोई छवि अपलोड नहीं की गई",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...images.map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: ImageBox(path: url),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
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

  // ── UI helpers ──
  Widget _cardHeader(
    IconData icon,
    String hindi,
    String english, {
    Color headerColor = darkNavy,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerColor == darkNavy
              ? [darkNavy, navyBlue]
              : [headerColor.withOpacity(0.9), headerColor],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: headerColor == darkNavy ? gold : Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hindi,
                style: TextStyle(
                  color: headerColor == darkNavy
                      ? Colors.white54
                      : Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                english,
                style: TextStyle(
                  color: headerColor == darkNavy ? gold : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: saffron, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: darkNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [saffron.withOpacity(0.15), Colors.transparent],
          ),
        ),
      );

  // ── Voice note recorder widget ──
  Widget _buildVoiceRecorder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "VOICE NOTE (OPTIONAL)",
          style: TextStyle(
            fontSize: 9,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),

        // Recording in progress
        if (_isRecording)
          _recordingIndicator()
        // Recorded — show playback controls
        else if (_recordedPath != null)
          _recordedPreview()
        // Idle — show record button
        else
          _recordButton(),
      ],
    );
  }

  Widget _recordButton() {
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          border: Border.all(color: saffron.withOpacity(0.5), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: saffron.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [saffron, deepSaffron]),
                boxShadow: [
                  BoxShadow(
                      color: saffron.withOpacity(0.4), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "आवाज़ नोट रिकॉर्ड करें",
                  style: TextStyle(
                    color: saffron,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "TAP TO RECORD",
                  style: TextStyle(
                    color: darkNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withOpacity(0.05),
      ),
      child: Row(
        children: [
          // Pulsing red dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 700),
            builder: (_, val, child) => Opacity(opacity: val, child: child),
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "रिकॉर्डिंग हो रही है...",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "RECORDING  ${_formatDuration(_recordDuration)}",
                  style: const TextStyle(
                    color: darkNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.15),
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: const Icon(Icons.stop, color: Colors.red, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordedPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: indiaGreen.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: indiaGreen.withOpacity(0.05),
      ),
      child: Row(
        children: [
          // Play / stop button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isPlaying
                      ? [indiaGreen, Colors.green.shade700]
                      : [saffron, deepSaffron],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isPlaying ? indiaGreen : saffron)
                        .withOpacity(0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "रिकॉर्डिंग तैयार है",
                  style: TextStyle(
                    color: indiaGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "VOICE NOTE  ${_formatDuration(_recordDuration)}",
                  style: const TextStyle(
                    color: darkNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Re-record button
          GestureDetector(
            onTap: () {
              _deleteRecording();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Edit Complaint",
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
              children: [
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient:
                        LinearGradient(colors: [saffron, gold, saffron]),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back_ios_new,
                                      color: Colors.white70, size: 14),
                                  SizedBox(width: 8),
                                  Text(
                                    "BACK",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Title banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [saffron, deepSaffron]),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: saffron.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.edit_document,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "शिकायत अपडेट करें",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Text(
                                      "UPDATE COMPLAINT STATUS",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Complaint details card ──
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: warmWhite,
                              child: Column(
                                children: [
                                  _cardHeader(Icons.receipt_long,
                                      "शिकायत विवरण", "COMPLAINT DETAILS"),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _detailRow(
                                            Icons.confirmation_number_outlined,
                                            "Complaint ID",
                                            widget.complaint.complaintId),
                                        _divider(),
                                        _detailRow(Icons.person_outline,
                                            "Citizen Name",
                                            widget.complaint.name),
                                        _divider(),
                                        _detailRow(Icons.phone_outlined,
                                            "Mobile No.",
                                            widget.complaint.mobileNo),
                                        _divider(),
                                        _detailRow(Icons.email_outlined,
                                            "Email",
                                            widget.complaint.email.isNotEmpty
                                                ? widget.complaint.email
                                                : "Not Provided"),
                                        _divider(),
                                        _detailRow(
                                            Icons.description_outlined,
                                            "Description",
                                            widget.complaint.description),
                                        _divider(),
                                        // _detailRow(
                                        //     Icons.location_on_outlined,
                                        //     "Location",
                                        //     widget.complaint.location),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Status management card ──
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: warmWhite,
                              child: Column(
                                children: [
                                  _cardHeader(Icons.track_changes,
                                      "वर्तमान स्थिति", "STATUS MANAGEMENT"),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "CURRENT STATUS",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF999999),
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            statusBadge(
                                                widget.complaint.status),
                                          ],
                                        ),
                                        if (!isCompleted) ...[
                                          const SizedBox(height: 16),
                                          const Text(
                                            "UPDATE TO",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF999999),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: saffron, width: 1.5),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child:
                                                DropdownButtonFormField<String>(
                                              value: selectedStatus,
                                              decoration:
                                                  const InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 14),
                                                border: InputBorder.none,
                                                prefixIcon: Icon(
                                                    Icons.swap_horiz,
                                                    color: saffron),
                                              ),
                                              style: const TextStyle(
                                                color: darkNavy,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                              dropdownColor: warmWhite,
                                              icon: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: saffron),
                                              items: getStatusOptions(),
                                              onChanged: (v) => setState(
                                                  () => selectedStatus = v!),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Actions taken card (shown when completing) ──
                          if (selectedStatus == "complete" ||
                              isCompleted) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                color: warmWhite,
                                child: Column(
                                  children: [
                                    _cardHeader(
                                      Icons.task_alt,
                                      "कार्रवाई विवरण",
                                      "ACTIONS TAKEN",
                                      headerColor: indiaGreen,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: isCompleted
                                          // Read-only view
                                          ? Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: indiaGreen
                                                    .withOpacity(0.07),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: indiaGreen
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .check_circle_outline,
                                                      color: indiaGreen,
                                                      size: 18),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      widget.complaint
                                                          .actionTaken,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: darkNavy,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          // Editable — description + voice
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Hint
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(
                                                          10),
                                                  margin: const EdgeInsets
                                                      .only(bottom: 14),
                                                  decoration: BoxDecoration(
                                                    color: saffron
                                                        .withOpacity(0.07),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: saffron
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: const [
                                                      Icon(Icons.info_outline,
                                                          color: saffron,
                                                          size: 14),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          "Provide a description, a voice note, or both.",
                                                          style: TextStyle(
                                                            color: saffron,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Description field
                                                const Text(
                                                  "DESCRIPTION (OPTIONAL)",
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Color(0xFF999999),
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                AppTextField(
                                                  label:
                                                      "Describe the actions taken",
                                                  controller:
                                                      actionDescriptionController,
                                                  maxLines: 3,
                                                  validator: (_) => null,
                                                ),

                                                const SizedBox(height: 16),

                                                // OR divider
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Divider(
                                                          color: Colors
                                                              .grey.shade300),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 10),
                                                      child: Text(
                                                        "OR",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey.shade500,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 2,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Divider(
                                                          color: Colors
                                                              .grey.shade300),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 16),

                                                // Voice recorder
                                                _buildVoiceRecorder(),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // ── Image upload card ──
                          if ((selectedStatus == "complete" ||
                                  isCompleted) &&
                              !isCompleted) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                color: warmWhite,
                                child: Column(
                                  children: [
                                    _cardHeader(
                                      Icons.photo_camera,
                                      "साक्ष्य चित्र",
                                      "UPLOAD EVIDENCE",
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: ComplaintImageSection(
                                        complaintId:
                                            widget.complaint.complaintId,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── Submit / Resolved banner ──
                          if (!isCompleted)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    isSubmitting ? null : updateComplaint,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  disabledBackgroundColor:
                                      Colors.grey.shade300,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: isSubmitting
                                        ? null
                                        : const LinearGradient(
                                            colors: [saffron, deepSaffron],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    color: isSubmitting
                                        ? Colors.grey.shade300
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSubmitting
                                        ? []
                                        : [
                                            BoxShadow(
                                              color:
                                                  saffron.withOpacity(0.5),
                                              blurRadius: 14,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: isSubmitting
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.upload_rounded,
                                                  color: Colors.white,
                                                  size: 22),
                                              SizedBox(width: 10),
                                              Text(
                                                "SUBMIT UPDATE",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 2.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                color: indiaGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: indiaGreen.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: indiaGreen.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified,
                                        color: indiaGreen, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "शिकायत निपटाई गई",
                                        style: TextStyle(
                                          color: indiaGreen,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      Text(
                                        "COMPLAINT RESOLVED",
                                        style: TextStyle(
                                          color: indiaGreen,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
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
                ),
              ],
            ),
          ],
        ),
      ),
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
    for (final c in [
      Offset(size.width * 0.9, size.height * 0.05),
      Offset(size.width * 0.08, size.height * 0.6),
    ]) {
      for (int r = 20; r <= 160; r += 20)
        canvas.drawCircle(c, r.toDouble(), p);
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
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), lp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}