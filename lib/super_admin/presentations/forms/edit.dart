import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/super_admin/data/admin_details.dart';
import 'package:corporator_app/super_admin/domain/admin_repository.dart';
import 'package:flutter/material.dart';

class EditPage extends StatefulWidget {

  final AdminModel admin;

  const EditPage({
    super.key,
    required this.admin,
  });

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController locationController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();

    /// ✅ preload existing admin data
    nameController =
        TextEditingController(text: widget.admin.name);

    mobileController =
        TextEditingController(text: widget.admin.mobileNo);

    locationController =
        TextEditingController(text: widget.admin.location);

    emailController =
        TextEditingController(text: widget.admin.email);
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    locationController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Edit Admin",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty
                        ? "Enter name"
                        : null,
              ),

              const SizedBox(height: 15),

              /// MOBILE
              TextFormField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Mobile Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.length != 10
                        ? "Enter valid 10 digit mobile number"
                        : null,
              ),

              const SizedBox(height: 15),

              /// LOCATION
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty
                        ? "Enter location"
                        : null,
              ),

              const SizedBox(height: 15),

              /// EMAIL
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Mail ID",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || !value.contains("@")
                        ? "Enter valid email"
                        : null,
              ),

              const SizedBox(height: 25),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  child: const Text("Save Admin"),
                  onPressed: () async {

                    if (!_formKey.currentState!.validate()) return;

                    await AdminRepository().updateAdmin(
                      widget.admin.uid,
                      {
                        "name": nameController.text,
                        "mobileNo": mobileController.text,
                        "location": locationController.text,
                        "email": emailController.text,
                      },
                    );

                    Navigator.pop(context);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}