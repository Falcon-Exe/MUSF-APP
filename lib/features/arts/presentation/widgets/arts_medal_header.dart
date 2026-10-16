// lib/features/arts/presentation/widgets/arts_medal_header.dart

import 'package:flutter/material.dart';

class ArtsMedalHeader extends StatelessWidget {
  final int gold;
  final int silver;
  final int bronze;
  final String selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;

  const ArtsMedalHeader({
    super.key,
    required this.gold,
    required this.silver,
    required this.bronze,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: const BoxDecoration(
        color: Color(0xFF003366),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search event...",
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _medalStat("🥇 Gold", gold.toString(), Colors.amber),
              _medalStat("🥈 Silver", silver.toString(), Colors.grey[300]!),
              _medalStat("🥉 Bronze", bronze.toString(), Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 10),
          _buildCategoryToggle(),
        ],
      ),
    );
  }

  Widget _medalStat(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryToggle() {
    return Container(
      height: 45,
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTabItem("On-Stage"),
          _buildTabItem("Off-Stage"),
        ],
      ),
    );
  }

  Widget _buildTabItem(String category) {
    bool isSelected = selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () => onCategoryChanged(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            category,
            style: TextStyle(
              color: isSelected ? const Color(0xFF003366) : Colors.white70,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
