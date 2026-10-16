// lib/features/finance/presentation/widgets/collection_summary_header.dart

import 'package:flutter/material.dart';

class CollectionSummaryHeader extends StatelessWidget {
  final String title;
  final int overallTotal;
  final int classTotal;
  final int classLiveBalance;
  final Color themeColor;

  const CollectionSummaryHeader({
    super.key,
    required this.title,
    required this.overallTotal,
    required this.classTotal,
    required this.classLiveBalance,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("₹ $overallTotal", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricColumn("CLASS COLLECTION", "₹ $classTotal", const Color(0xFF69F0AE)),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildMetricColumn("CLASS LIVE BALANCE", "₹ $classLiveBalance", const Color(0xFFFFD54F)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
