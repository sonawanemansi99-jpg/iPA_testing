import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {

  // final String ward;

  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Admin Dashboard -"),
      ),

      body: Text("Admin")

    );

  }

}