import 'package:flutter/material.dart';

class HabitCard extends StatelessWidget {
  final String title;
  final String category;
  final Color color;
  final IconData icon;
  final bool done;
  final VoidCallback onToggle;

  const HabitCard({
    super.key,
    required this.title,
    required this.category,
    required this.color,
    required this.icon,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: done
                    ? Colors.green.withOpacity(0.15)
                    : color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : icon,
                color: done ? Colors.green : color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration:
                    done ? TextDecoration.lineThrough : null,
                    color: done ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
