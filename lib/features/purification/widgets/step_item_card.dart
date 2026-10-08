import 'package:flutter/material.dart';

class StepItemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAudioPressed;

  const StepItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAudioPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.lightBlue.shade50,
            child: Icon(icon, color: Colors.lightBlue.shade800),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: Container(
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.volume_up_outlined,
                color: Colors.lightBlue.shade800,
              ),
              onPressed: onAudioPressed,
            ),
          ),
        ),
      ),
    );
  }
}
