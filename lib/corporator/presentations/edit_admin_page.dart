import 'package:corporator_app/corporator/services/corporator_service.dart';
import 'package:flutter/material.dart';

class EditAdminPage extends StatefulWidget {
  final Map<String, dynamic> admin;

  const EditAdminPage({super.key, required this.admin});

  @override
  State<EditAdminPage> createState() => _EditAdminPageState();
}

class _EditAdminPageState extends State<EditAdminPage> {
  final CorporatorService _service = CorporatorService();

  List<TextEditingController> zoneControllers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadZones();
  }

  Future<void> loadZones() async {
    final zoneIds = List<String>.from(widget.admin['zoneIds'] ?? []);

    final zoneNames = await _service.getZoneNamesFromIds(zoneIds);

    setState(() {
      zoneControllers =
          zoneNames.map((z) => TextEditingController(text: z)).toList();

      if (zoneControllers.isEmpty) {
        zoneControllers.add(TextEditingController());
      }

      isLoading = false;
    });
  }

  Future<void> updateZones() async {
    final updatedZones = zoneControllers
        .map((c) => c.text.trim())
        .where((z) => z.isNotEmpty)
        .toList();

    if (updatedZones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one zone required")),
      );
      return;
    }

    await _service.updateAdminZones(
      adminId: widget.admin['uid'],
      corporatorId: widget.admin['corporatorId'],
      newZoneNames: updatedZones,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Admin")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _readOnlyField("Name", admin['name'] ?? ""),
                  _readOnlyField("Email", admin['email'] ?? ""),
                  _readOnlyField("Mobile", admin['mobile'] ?? ""),
                  _readOnlyField("Location", admin['location'] ?? ""),

                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Edit Zones",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Column(
                    children:
                        List.generate(zoneControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: zoneControllers[index],
                                decoration: const InputDecoration(
                                  labelText: "Zone Name",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (index != 0)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    zoneControllers.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          zoneControllers
                              .add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add Zone"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: updateZones,
                    child: const Text("Update"),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}