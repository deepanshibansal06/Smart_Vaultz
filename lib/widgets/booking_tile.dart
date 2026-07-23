import 'package:flutter/material.dart';

class BookingTile extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const BookingTile({super.key, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(time),
      trailing: ElevatedButton(
        onPressed: onTap,
        child: const Text("Book"),
      ),
    );
  }
}