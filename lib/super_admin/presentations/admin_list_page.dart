import 'package:corporator_app/core/widgets/appbar.dart';
import 'package:corporator_app/super_admin/services/admin_service.dart';
import 'package:flutter/material.dart';

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  final AdminService _adminService = AdminService();
  late Future<List<Map<String, dynamic>>> _adminsFuture;

  @override
  void initState() {
    super.initState();
    _adminsFuture = _adminService.fetchAdmins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context, title: "Admins"),
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
                child: Padding(
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
                      Row(
                        children: [
                          const Icon(Icons.email, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(email),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(mobile),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(location),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}