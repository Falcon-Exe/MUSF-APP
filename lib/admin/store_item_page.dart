import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class StoreItemPage extends StatelessWidget {
  const StoreItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Store Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.indigo,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_rounded), text: "Manage Stock"),
              Tab(
                icon: Icon(Icons.analytics_rounded),
                text: "Report & Analysis",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // TAB 1: MANAGE INVENTORY
            _InventoryTab(),

            // TAB 2: REPORT & ANALYSIS (WITH PDF)
            _ReportTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 1: MANAGE INVENTORY LIST (REDESIGNED STOCK UPDATE)
// =============================================================================
class _InventoryTab extends StatefulWidget {
  const _InventoryTab();

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  final int lowStockThreshold = 10;
  String _searchQuery = ""; // Added for search

  // 🟢 LOGIC: Update Stock securely
  Future<void> _updateQuantity(String docId, int currentQty, int change) async {
    if (currentQty + change < 0) return;
    try {
      await FirebaseFirestore.instance
          .collection('store_inventory')
          .doc(docId)
          .update({'quantity': FieldValue.increment(change)});
    } catch (e) {
      debugPrint("Error updating stock: $e");
    }
  }

  // 🟢 UI: New Elegant Stock Update Dialog
  void _showUpdateStockDialog(String docId, String itemName, int currentQty) {
    final TextEditingController qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Update Stock: $itemName",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Stock: $currentQty",
              style: const TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter Quantity",
                hintText: "e.g., 50",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              int amt = int.tryParse(qtyCtrl.text) ?? 0;
              if (amt > 0) {
                _updateQuantity(docId, currentQty, -amt); // Subtract
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.remove, color: Colors.white, size: 18),
            label: const Text("Deduct", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
          ElevatedButton.icon(
            onPressed: () {
              int amt = int.tryParse(qtyCtrl.text) ?? 0;
              if (amt > 0) {
                _updateQuantity(docId, currentQty, amt); // Add
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text("Add", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String docId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item?"),
        content: Text(
          "Are you sure you want to remove '$itemName' from inventory?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('store_inventory')
                  .doc(docId)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddItemForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Product",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🟢 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search products by name...",
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.indigo.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.indigo.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('store_inventory')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.indigo),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Filter docs based on search query
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? "No items in inventory. Tap + to add."
                          : "No products found matching '$_searchQuery'",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 20, 15, 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    int qty = data['quantity'] ?? 0;
                    bool isLowStock = qty < lowStockThreshold;

                    return InkWell(
                      onLongPress: () =>
                          _confirmDelete(doc.id, data['name'] ?? 'Item'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: isLowStock
                                ? Colors.red.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: isLowStock
                                        ? Colors.red[50]
                                        : Colors.indigo[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_rounded,
                                    color: isLowStock
                                        ? Colors.red
                                        : Colors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Cost: ₹${data['purchasePrice']}  •  Sale: ₹${data['price']}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "$qty ${data['unit']}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: isLowStock
                                            ? Colors.red
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (isLowStock)
                                      const Text(
                                        "LOW STOCK",
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 🟢 NEW ELEGANT STOCK UPDATE BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 35,
                              child: OutlinedButton.icon(
                                onPressed: () => _showUpdateStockDialog(
                                  doc.id,
                                  data['name'],
                                  qty,
                                ),
                                icon: const Icon(
                                  Icons.edit_note_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  "Update Stock",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.indigo,
                                  side: BorderSide(
                                    color: Colors.indigo.withValues(alpha: 0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 2: REPORT & ANALYSIS (WITH PDF GENERATION)
// =============================================================================
class _ReportTab extends StatelessWidget {
  const _ReportTab();

  final int lowStockThreshold = 10;

  // 🟢 LOGIC: GENERATE AND DOWNLOAD PDF REPORT
  Future<void> _generatePdfReport(
    List<QueryDocumentSnapshot> docs,
    double investment,
    double retail,
    double profit,
  ) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Store Inventory Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                  ),
                  pw.Text(
                    dateStr,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Financial Summary Box in PDF
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _pdfSummaryColumn(
                    "Total Investment",
                    "Rs. ${investment.toStringAsFixed(0)}",
                  ),
                  _pdfSummaryColumn(
                    "Retail Value",
                    "Rs. ${retail.toStringAsFixed(0)}",
                  ),
                  _pdfSummaryColumn(
                    "Potential Profit",
                    "Rs. ${profit.toStringAsFixed(0)}",
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Table Header
            pw.Text(
              "Detailed Stock List",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // The Actual Table
            pw.TableHelper.fromTextArray(
              headers: [
                'Item Name',
                'Unit',
                'Qty',
                'Cost (Rs)',
                'Price (Rs)',
                'Total Value',
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
              data: docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                int qty = data['quantity'] ?? 0;
                double cost = (data['purchasePrice'] ?? 0).toDouble();
                return [
                  data['name'] ?? 'Unknown',
                  data['unit'] ?? '-',
                  qty.toString(),
                  cost.toStringAsFixed(2),
                  (data['price'] ?? 0).toDouble().toStringAsFixed(2),
                  (qty * cost).toStringAsFixed(2), // Total Value per item
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // This triggers the device's native PDF viewer/sharing menu
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Inventory_Report_$dateStr.pdf',
    );
  }

  pw.Widget _pdfSummaryColumn(String title, String val) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          val,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('store_inventory')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.indigo),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        int totalUniqueItems = docs.length;
        int totalItemQuantity = 0;
        double totalInvestment = 0;
        double totalRetailValue = 0;
        List<Map<String, dynamic>> lowStockList = [];

        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          int qty = data['quantity'] ?? 0;
          double pPrice = (data['purchasePrice'] ?? 0).toDouble();
          double sPrice = (data['price'] ?? 0).toDouble();

          totalItemQuantity += qty;
          totalInvestment += (qty * pPrice);
          totalRetailValue += (qty * sPrice);

          if (qty < lowStockThreshold) {
            lowStockList.add({'id': doc.id, ...data});
          }
        }

        double potentialProfit = totalRetailValue - totalInvestment;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟢 NEW PDF BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: docs.isEmpty
                      ? null
                      : () => _generatePdfReport(
                          docs,
                          totalInvestment,
                          totalRetailValue,
                          potentialProfit,
                        ),
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Download PDF Report",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: Colors.redAccent.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                "Financial Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.indigo, Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildWhiteStatRow(
                      "Total Investment",
                      "₹${totalInvestment.toStringAsFixed(0)}",
                    ),
                    const Divider(color: Colors.white24, height: 30),
                    _buildWhiteStatRow(
                      "Expected Retail Value",
                      "₹${totalRetailValue.toStringAsFixed(0)}",
                    ),
                    const Divider(color: Colors.white24, height: 30),
                    _buildWhiteStatRow(
                      "Potential Profit",
                      "₹${potentialProfit.toStringAsFixed(0)}",
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                "Stock Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildGridStatCard(
                      "Unique Products",
                      "$totalUniqueItems",
                      Icons.category_rounded,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildGridStatCard(
                      "Total Items",
                      "$totalItemQuantity",
                      Icons.inventory_2_rounded,
                      Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Needs Restocking",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${lowStockList.length} Alerts",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              if (lowStockList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 40,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "All stock levels are healthy!",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lowStockList.length,
                  itemBuilder: (context, index) {
                    var item = lowStockList[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
                        ),
                        title: Text(
                          item['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Only ${item['quantity']} ${item['unit']} remaining",
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhiteStatRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? Colors.white : Colors.white70,
            fontSize: isHighlight ? 16 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? Colors.greenAccent : Colors.white,
            fontSize: isHighlight ? 24 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGridStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOTTOM SHEET: ADD NEW ITEM
// =============================================================================
class _AddItemForm extends StatefulWidget {
  const _AddItemForm();

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _purchaseCtrl = TextEditingController();
  final TextEditingController _saleCtrl = TextEditingController();
  String _selectedUnit = "PCS";
  bool _isLoading = false;

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('store_inventory').add({
        'name': _nameCtrl.text.trim(),
        'purchasePrice': double.tryParse(_purchaseCtrl.text) ?? 0.0,
        'price': double.tryParse(_saleCtrl.text) ?? 0.0,
        'unit': _selectedUnit,
        'quantity': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Add New Product",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchaseCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: "Purchase Cost",
                        prefixText: "₹ ",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _saleCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: "Selling Price",
                        prefixText: "₹ ",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  labelText: "Select Unit",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ["PCS", "KG", "LTR", "BOX", "DOZEN"]
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedUnit = val!),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Item",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
