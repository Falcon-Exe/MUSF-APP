// lib/features/prd/presentation/widgets/prd_task_card.dart

import 'package:flutter/material.dart';
import 'prd_theme.dart';

class PrdTaskCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PrdTaskCard({
    super.key,
    required this.data,
    required this.docId,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    String status = data['status'] ?? 'Pending';
    Color statusColor = PrdTheme.getStatusColor(status);
    IconData statusIcon = PrdTheme.getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (data['committeeName'] ?? data['committee'] ?? 'General').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    PrdTheme.getTypeIcon(data['type']),
                    color: PrdTheme.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data['requestTitle'] ?? data['title'] ?? 'Untitled Request',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: PrdTheme.textMain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['description'] ?? 'No details provided.',
                style: const TextStyle(
                  color: PrdTheme.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PrdTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Deadline: ",
                      style: TextStyle(
                        fontSize: 12,
                        color: PrdTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      data['deadline'] ?? 'Not set',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
