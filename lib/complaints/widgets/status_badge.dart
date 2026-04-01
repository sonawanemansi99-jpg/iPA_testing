import 'package:flutter/material.dart';

Widget statusBadge(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case "pending":
        color = Colors.orange;
        break;
      case "in progress":
        color = Colors.blue;
        break;
      case "complete":
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
