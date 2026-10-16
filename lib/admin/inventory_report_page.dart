import 'package:flutter/material.dart';

class InventoryReportPage extends StatefulWidget {
  const InventoryReportPage({super.key});

  @override
  State<InventoryReportPage> createState() => _InventoryReportPageState();
}

class _InventoryReportPageState extends State<InventoryReportPage> {
  // Filter State
  String _selectedFilter = 'This Month';
  final List<String> _filters = ['Today', 'This Week', 'This Month', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: AppBar(
        title: const Text("Reports & Analytics", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Date Filter ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  bool isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: Colors.indigo,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey[200]!)),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Profit & Loss Section ---
            const Text("Profit & Loss", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.indigo, Color(0xFF5C6BC0)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Text("Net Profit", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text("₹ 12,450", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTransparentStat("Income", "₹ 45,200", Icons.arrow_upward, Colors.greenAccent),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _buildTransparentStat("Expense", "₹ 32,750", Icons.arrow_downward, Colors.redAccent),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // --- 3. Stock Summary Section ---
            const Text("Stock Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildStockCard("Total Items", "142", Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStockCard("Total Value", "₹ 1.2L", Colors.purple)),
              ],
            ),
            const SizedBox(height: 12),
            // Low Stock Alert Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Low Stock Alert", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      Text("5 items are below minimum quantity", style: TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.red[300]),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 4. Detailed List (Top Movers) ---
            const Text("Top Moving Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildReportListItem("Milky Mist Ghee", "Sold: 45 units", "+ ₹2,100", true),
            _buildReportListItem("Aashirvaad Atta", "Sold: 30 units", "+ ₹1,800", true),
            _buildReportListItem("Coca Cola 1L", "Sold: 12 units", "+ ₹450", false), // Less movement
          ],
        ),
      ),
    );
  }

  // Helper Widget: P&L Stats inside the Blue Card
  Widget _buildTransparentStat(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Helper Widget: Stock Summary Cards
  Widget _buildStockCard(String title, String value, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor)),
        ],
      ),
    );
  }

  // Helper Widget: List Item for Reports
  Widget _buildReportListItem(String name, String subtitle, String profit, bool isHigh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.trending_up, color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Text(profit, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}
