import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/domain/model/complaint_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CorporatorComplaintsPage extends StatefulWidget {
  const CorporatorComplaintsPage({super.key});

  @override
  State<CorporatorComplaintsPage> createState() =>
      _CorporatorComplaintsPageState();
}

class _CorporatorComplaintsPageState extends State<CorporatorComplaintsPage>
    with TickerProviderStateMixin {

  static const saffron     = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold        = Color(0xFFFFD700);
  static const navyBlue    = Color(0xFF002868);
  static const darkNavy    = Color(0xFF001A45);
  static const warmWhite   = Color(0xFFFFFDF7);
  static const indiaGreen  = Color(0xFF138808);

  // Status filter: all / pending / in progress / complete
  String _statusFilter = 'all';
  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'ALL'},
    {'value': 'pending', 'label': 'PENDING'},
    {'value': 'in progress', 'label': 'IN PROGRESS'},
    {'value': 'complete', 'label': 'COMPLETE'},
  ];

  List<ComplaintModel> _complaints = [];
  bool _loading = true;
  String? _error;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (_currentUid == null) throw Exception("Not logged in");

      final snap = await FirebaseFirestore.instance
          .collection('complaints')
          .where('corporatorId', isEqualTo: _currentUid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _complaints = snap.docs.map(ComplaintModel.fromFirestore).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Filter complaints by status
  List<ComplaintModel> get _filtered {
    if (_statusFilter == 'all') return _complaints;
    return _complaints.where((c) => c.status == _statusFilter).toList();
  }

  // Status styles
  Color _statusColor(String status) {
    switch (status) {
      case 'complete':
        return indiaGreen;
      case 'in progress':
        return saffron;
      default:
        return Colors.red.shade700;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'complete':
        return indiaGreen.withOpacity(0.12);
      case 'in progress':
        return saffron.withOpacity(0.12);
      default:
        return Colors.red.withOpacity(0.10);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'complete':
        return Icons.check_circle_outline;
      case 'in progress':
        return Icons.timelapse;
      default:
        return Icons.pending_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Complaints",
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkNavy, navyBlue, Color(0xFF003A8C)],
          ),
        ),
        child: Column(
          children: [
            // Status filter chips
            _buildStatusFilter(),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: gold))
                  : _error != null
                      ? _buildError()
                      : _buildComplaintList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((opt) {
            final selected = _statusFilter == opt['value'];
            return GestureDetector(
              onTap: () => setState(() => _statusFilter = opt['value']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [saffron, deepSaffron])
                      : null,
                  color: selected ? null : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? saffron : gold.withOpacity(0.3),
                    width: selected ? 0 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: saffron.withOpacity(0.4), blurRadius: 8)]
                      : [],
                ),
                child: Text(
                  opt['label']!,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
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
    final list = _filtered;
    if (list.isEmpty) return _buildEmpty();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (_, i) => _complaintCard(list[i]),
    );
  }

  Widget _complaintCard(ComplaintModel c) {
    return GestureDetector(
      onTap: () => _showComplaintDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: warmWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gold.withOpacity(0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.complaintId,
                    style: const TextStyle(
                        color: darkNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg(c.status),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(c.status).withOpacity(0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statusIcon(c.status), color: _statusColor(c.status), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      c.status.toUpperCase(),
                      style: TextStyle(
                          color: _statusColor(c.status),
                          fontSize: 9,
                          fontWeight: FontWeight.w900),
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showComplaintDetail(ComplaintModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: warmWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(16),
            children: [
              Text(c.complaintId,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("Citizen: ${c.name}"),
              Text("Email: ${c.email}"),
              Text("Mobile: ${c.mobileNo}"),
              const SizedBox(height: 8),
              Text("Zone: ${c.zoneName}"),
              const SizedBox(height: 8),
              Text("Status: ${c.status}"),
              const SizedBox(height: 8),
              Text("Description:\n${c.description}"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, color: gold.withOpacity(0.4), size: 64),
        const SizedBox(height: 16),
        Text("No complaints found",
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 52),
        const SizedBox(height: 12),
        Text(_error ?? "Something went wrong",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _fetchComplaints,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [saffron, deepSaffron]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("RETRY",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
          ),
        ),
      ]),
    );
  }
}