import 'dart:async';
import 'dart:io';
import 'package:corporator_app/core/widgets/app_text_input_field.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/complaints/widgets/status_badge.dart';
import 'package:corporator_app/services/complaint_service.dart';
import 'package:corporator_app/services/media_service.dart'; // Ensure this is imported!
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

class EditComplaintStatus extends StatefulWidget {
  final Map<String, dynamic> complaintMap; // Using Zero-Trust Map
  const EditComplaintStatus({super.key, required this.complaintMap});
  
  @override
  State<EditComplaintStatus> createState() => _EditComplaintStatusState();
}

class _EditComplaintStatusState extends State<EditComplaintStatus> {
  final ComplaintService _complaintService = ComplaintService();
  final MediaService _mediaService = MediaService();

  late String initialStatus;
  late String selectedStatus;
  late String complaintId;
  
  final actionDescriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  // ── Resolution Image (Mandatory for COMPLETED) ──
  File? _resolutionImageFile;
  final ImagePicker _picker = ImagePicker();

  // ── Voice note ──
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedPath;   
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  static const saffron    = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold       = Color(0xFFFFD700);
  static const navyBlue   = Color(0xFF002868);
  static const darkNavy   = Color(0xFF001A45);
  static const warmWhite  = Color(0xFFFFFDF7);
  static const indiaGreen = Color(0xFF138808);

  bool get isCompleted => initialStatus == "COMPLETED" || initialStatus == "UNRESOLVED";

  bool get _hasActionInput =>
      actionDescriptionController.text.trim().isNotEmpty || _recordedPath != null;

  @override
  void initState() {
    super.initState();
    // Safely extract values from Spring Boot Map
    complaintId = widget.complaintMap['id']?.toString() ?? widget.complaintMap['complaintId']?.toString() ?? '';
    initialStatus = widget.complaintMap['status']?.toString().toUpperCase() ?? "PENDING";
    selectedStatus = initialStatus;

    if (isCompleted) {
      actionDescriptionController.text = widget.complaintMap['resolutionDescription'] ?? '';
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

  // ── STRICT DOMAIN VALIDATION FOR DROPDOWN ──
  List<DropdownMenuItem<String>> getStatusOptions() {
    if (initialStatus == "PENDING") {
      return const [
        DropdownMenuItem(value: "PENDING", child: Text("Pending")),
        DropdownMenuItem(value: "IN_PROGRESS", child: Text("In Progress")),
        DropdownMenuItem(value: "DEFERRED", child: Text("Deferred")),
        DropdownMenuItem(value: "UNRESOLVED", child: Text("Unresolved")),
      ];
    } else if (initialStatus == "IN_PROGRESS") {
      return const [
        DropdownMenuItem(value: "IN_PROGRESS", child: Text("In Progress")),
        DropdownMenuItem(value: "COMPLETED", child: Text("Completed")),
        DropdownMenuItem(value: "UNRESOLVED", child: Text("Unresolved")),
      ];
    }
    // Terminal States (Completed, Unresolved, Deferred without path back)
    return [
      DropdownMenuItem(value: initialStatus, child: Text(initialStatus.replaceAll('_', ' ')))
    ];
  }

  Future<void> _pickResolutionImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _resolutionImageFile = File(pickedFile.path);
      });
    }
  }

  // ── Recording helpers ──
  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showSnack("Microphone permission denied", isError: true);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/admin_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
        _recordedPath = null;
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
      if (path != null && await File(path).exists()) {
        setState(() {
          _isRecording = false;
          _recordedPath = path;
        });
      } else {
        setState(() => _isRecording = false);
      }
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── SUBMIT / INTEGRATION ──
  Future<void> updateComplaint() async {
    // 1. Check if trying to complete without mandatory domain requirements
    if (selectedStatus == "COMPLETED") {
      if (_resolutionImageFile == null) {
        _showSnack("Domain Error: Resolution Image is mandatory for COMPLETED status.", isError: true);
        return;
      }
      if (!_hasActionInput) {
        _showSnack("Domain Error: Please provide a text description or record a voice note.", isError: true);
        return;
      }
    }

    try {
      setState(() => isSubmitting = true);

      // If resolving...
      if (selectedStatus == "COMPLETED") {
        // Upload Media concurrently
        String? uploadedImageUrl;
        String? uploadedVoiceUrl;

        // Upload Image (Guaranteed to exist due to check above)
        uploadedImageUrl = await _mediaService.uploadMediaToCloudinary(_resolutionImageFile!);
        
        // Upload Voice Note if present
        if (_recordedPath != null) {
          uploadedVoiceUrl = await _mediaService.uploadMediaToCloudinary(File(_recordedPath!), isAudio: true);
        }

        // Call the strict resolution endpoint
        await _complaintService.resolveComplaint(
          complaintId,
          uploadedImageUrl,
          actionDescriptionController.text.trim().isEmpty ? null : actionDescriptionController.text.trim(),
          uploadedVoiceUrl,
        );

      } else {
        // For basic status changes (IN_PROGRESS, DEFERRED, UNRESOLVED)
        await _complaintService.updateComplaintStatus(complaintId, selectedStatus);
      }

      if (!mounted) return;
      _showSnack("स्थिति सफलतापूर्वक अपडेट की गई! (Status Updated)", isError: false);
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
            Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : indiaGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── UI helpers ──
  Widget _cardHeader(IconData icon, String hindi, String english, {Color headerColor = darkNavy}) {
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
            child: Icon(icon, color: headerColor == darkNavy ? gold : Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hindi, style: TextStyle(color: headerColor == darkNavy ? Colors.white54 : Colors.white70, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
              Text(english, style: TextStyle(color: headerColor == darkNavy ? gold : Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
                  Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Color(0xFF999999), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 3),
                  Text(value, style: const TextStyle(fontSize: 14, color: darkNavy, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [saffron.withOpacity(0.15), Colors.transparent])),
      );

  // ── Voice note recorder widget ──
  Widget _buildVoiceRecorder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("VOICE NOTE", style: TextStyle(fontSize: 9, color: Color(0xFF999999), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        if (_isRecording) _recordingIndicator()
        else if (_recordedPath != null) _recordedPreview()
        else _recordButton(),
      ],
    );
  }

  Widget _recordButton() {
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(border: Border.all(color: saffron.withOpacity(0.5), width: 1.5), borderRadius: BorderRadius.circular(12), color: saffron.withOpacity(0.05)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [saffron, deepSaffron]), boxShadow: [BoxShadow(color: saffron.withOpacity(0.4), blurRadius: 10)]),
              child: const Icon(Icons.mic, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("आवाज़ नोट रिकॉर्ड करें", style: TextStyle(color: saffron, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
                Text("TAP TO RECORD", style: TextStyle(color: darkNavy, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
      decoration: BoxDecoration(border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5), borderRadius: BorderRadius.circular(12), color: Colors.red.withOpacity(0.05)),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 700),
            builder: (_, val, child) => Opacity(opacity: val, child: child),
            child: Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("रिकॉर्डिंग हो रही है...", style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
                Text("RECORDING  ${_formatDuration(_recordDuration)}", style: const TextStyle(color: darkNavy, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.15), border: Border.all(color: Colors.red, width: 1.5)), child: const Icon(Icons.stop, color: Colors.red, size: 20)),
          ),
        ],
      ),
    );
  }

  Widget _recordedPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(border: Border.all(color: indiaGreen.withOpacity(0.4), width: 1.5), borderRadius: BorderRadius.circular(12), color: indiaGreen.withOpacity(0.05)),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: _isPlaying ? [indiaGreen, Colors.green.shade700] : [saffron, deepSaffron]), boxShadow: [BoxShadow(color: (_isPlaying ? indiaGreen : saffron).withOpacity(0.35), blurRadius: 8)]),
              child: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("रिकॉर्डिंग तैयार है", style: TextStyle(color: indiaGreen, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
                Text("VOICE NOTE  ${_formatDuration(_recordDuration)}", style: const TextStyle(color: darkNavy, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _deleteRecording,
            child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1), border: Border.all(color: Colors.red.withOpacity(0.4))), child: const Icon(Icons.delete_outline, color: Colors.red, size: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Update Status",
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [darkNavy, navyBlue, Color(0xFF003A8C)], stops: [0.0, 0.4, 1.0]),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
            Column(
              children: [
                Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron]))),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.2))),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 14), SizedBox(width: 8), Text("BACK", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2))]),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(gradient: const LinearGradient(colors: [saffron, deepSaffron]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: saffron.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                            child: Row(
                              children: const [
                                Icon(Icons.edit_document, color: Colors.white, size: 20), SizedBox(width: 10),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("शिकायत अपडेट करें", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)), Text("UPDATE COMPLAINT", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2))]),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: warmWhite,
                              child: Column(
                                children: [
                                  _cardHeader(Icons.receipt_long, "शिकायत विवरण", "COMPLAINT DETAILS"),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _detailRow(Icons.confirmation_number_outlined, "Complaint ID", complaintId), _divider(),
                                        _detailRow(Icons.person_outline, "Citizen Name", widget.complaintMap['citizenName'] ?? 'N/A'), _divider(),
                                        _detailRow(Icons.description_outlined, "Description", widget.complaintMap['description'] ?? 'N/A'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: warmWhite,
                              child: Column(
                                children: [
                                  _cardHeader(Icons.track_changes, "वर्तमान स्थिति", "STATUS MANAGEMENT"),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text("CURRENT STATUS", style: TextStyle(fontSize: 10, color: Color(0xFF999999), fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                            const SizedBox(width: 12),
                                            statusBadge(initialStatus),
                                          ],
                                        ),
                                        if (!isCompleted) ...[
                                          const SizedBox(height: 16),
                                          const Text("UPDATE TO", style: TextStyle(fontSize: 10, color: Color(0xFF999999), fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                          const SizedBox(height: 8),
                                          Container(
                                            decoration: BoxDecoration(border: Border.all(color: saffron, width: 1.5), borderRadius: BorderRadius.circular(10)),
                                            child: DropdownButtonFormField<String>(
                                              value: selectedStatus,
                                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14), border: InputBorder.none, prefixIcon: Icon(Icons.swap_horiz, color: saffron)),
                                              style: const TextStyle(color: darkNavy, fontWeight: FontWeight.w700, fontSize: 15),
                                              dropdownColor: warmWhite,
                                              icon: const Icon(Icons.keyboard_arrow_down, color: saffron),
                                              items: getStatusOptions(),
                                              onChanged: (v) => setState(() => selectedStatus = v!),
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
                          
                          // ── Actions taken card (Show if completing) ──
                          if (selectedStatus == "COMPLETED" && !isCompleted) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                color: warmWhite,
                                child: Column(
                                  children: [
                                    _cardHeader(Icons.task_alt, "कार्रवाई विवरण", "RESOLUTION DETAILS", headerColor: indiaGreen),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 14),
                                            decoration: BoxDecoration(color: saffron.withOpacity(0.07), borderRadius: BorderRadius.circular(8), border: Border.all(color: saffron.withOpacity(0.3))),
                                            child: Row(children: const [Icon(Icons.info_outline, color: saffron, size: 14), SizedBox(width: 8), Expanded(child: Text("Mandatory: Upload Image AND (Description OR Voice Note)", style: TextStyle(color: saffron, fontSize: 11, fontWeight: FontWeight.w600)))]),
                                          ),
                                          
                                          // Image Picker for Resolution Evidence
                                          const Text("RESOLUTION IMAGE (MANDATORY)", style: TextStyle(fontSize: 9, color: Color(0xFF999999), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: _pickResolutionImage,
                                            child: Container(
                                              width: double.infinity, height: 120,
                                              decoration: BoxDecoration(border: Border.all(color: _resolutionImageFile == null ? Colors.grey : indiaGreen, width: 2), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade100),
                                              child: _resolutionImageFile == null 
                                                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.add_a_photo, color: Colors.grey, size: 30), SizedBox(height: 8), Text("Tap to capture photo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))])
                                                : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_resolutionImageFile!, fit: BoxFit.cover)),
                                            ),
                                          ),

                                          const SizedBox(height: 16),
                                          const Text("DESCRIPTION", style: TextStyle(fontSize: 9, color: Color(0xFF999999), fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                          const SizedBox(height: 8),
                                          AppTextField(label: "Describe the actions taken", controller: actionDescriptionController, maxLines: 3, validator: (_) => null),
                                          
                                          const SizedBox(height: 16),
                                          Row(children: [Expanded(child: Divider(color: Colors.grey.shade300)), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("OR / AND", style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2))), Expanded(child: Divider(color: Colors.grey.shade300))]),
                                          const SizedBox(height: 16),
                                          
                                          _buildVoiceRecorder(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          if (!isCompleted)
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: isSubmitting ? null : updateComplaint,
                                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, disabledBackgroundColor: Colors.grey.shade300),
                                child: Ink(
                                  decoration: BoxDecoration(gradient: isSubmitting ? null : const LinearGradient(colors: [saffron, deepSaffron], begin: Alignment.topLeft, end: Alignment.bottomRight), color: isSubmitting ? Colors.grey.shade300 : null, borderRadius: BorderRadius.circular(12), boxShadow: isSubmitting ? [] : [BoxShadow(color: saffron.withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 5))]),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: isSubmitting
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_rounded, color: Colors.white, size: 22), SizedBox(width: 10), Text("SUBMIT UPDATE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.5))]),
                                  ),
                                ),
                              ),
                            )
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
    final p = Paint()..color = Colors.white.withOpacity(0.025)..style = PaintingStyle.stroke..strokeWidth = 1;
    for (final c in [Offset(size.width * 0.9, size.height * 0.05), Offset(size.width * 0.08, size.height * 0.6)]) {
      for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
      final sp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(c, Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160), sp);
      }
    }
    final lp = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40) canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}