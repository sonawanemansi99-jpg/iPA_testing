import 'package:corporator_app/core/widgets/appbar.dart';
import 'package:corporator_app/corporator/presentations/edit_admin_page.dart';
import 'package:corporator_app/corporator/services/corporator_service.dart';
import 'package:flutter/material.dart';

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  final CorporatorService _corporatorService = CorporatorService();
  late Future<List<Map<String, dynamic>>> _adminsFuture;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  void _loadAdmins() {
    _adminsFuture = _corporatorService.fetchMyAdmins();
  }

  Future<void> _refreshAdmins() async {
    setState(() {
      _loadAdmins();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admins"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAdmins,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _adminsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No admins found"));
          }

          final admins = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              final name = admin['name'] ?? 'No Name';
              final email = admin['email'] ?? 'No Email';
              final mobile = admin['mobile'] ?? 'No Mobile';
              final location = admin['location'] ?? 'No Location';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _infoRow(Icons.email, email),
                          _infoRow(Icons.phone, mobile),
                          _infoRow(Icons.location_on, location),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditAdminPage(admin: admin),
                            ),
                          );
                          _refreshAdmins();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}
