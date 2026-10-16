// lib/features/finance/logic/finance_controller.dart

import 'package:flutter/material.dart';
import '../data/repositories/finance_repository.dart';
import '../data/repositories/supabase_finance_repository.dart';

class FinanceController extends ChangeNotifier {
  final FinanceRepository _repository;

  late final Stream<List<Map<String, dynamic>>> studentsStream;
  late final Stream<List<Map<String, dynamic>>> treasuryStream;
  late final Stream<List<Map<String, dynamic>>> aeroLedgerStream;

  // --- Dues State Variables ---
  String _selectedClass = "All";
  String _searchQuery = "";

  String get selectedClass => _selectedClass;
  String get searchQuery => _searchQuery;

  FinanceController({FinanceRepository? repository})
      : _repository = repository ?? SupabaseFinanceRepository() {
    studentsStream = _repository.getStudentsStream().asBroadcastStream();
    treasuryStream = _repository.getTreasuryStream().asBroadcastStream();
    aeroLedgerStream = _repository.getAeroLedgerStream().asBroadcastStream();
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _validateAmount(int amount) {
    if (amount < 0) throw "Amount cannot be negative.";
  }

  void _validateString(String value, String name) {
    if (value.trim().isEmpty) throw "$name cannot be empty.";
    if (value.contains("<script>") || value.contains("javascript:")) {
      throw "Invalid characters in $name.";
    }
  }

  void setClassFilter(String val) {
    _selectedClass = val;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- Stream Getters ---
  Stream<List<Map<String, dynamic>>> getPaymentHistory(
    String id,
    CollectionType type,
  ) =>
      _repository.getPaymentHistoryStream(id, type);

  Stream<List<Map<String, dynamic>>> getStudentSavings(String id) =>
      _repository.getStudentSavingsHistory(id);

  Stream<List<Map<String, dynamic>>> getPurchaseRequests(String status) =>
      _repository.getPurchaseRequestsStream(status);

  // --- Dues Logic ---
  Future<void> updateDues({
    required BuildContext context,
    required String docId,
    required String studentID,
    required int amount,
    required bool isAddingDebt,
    required CollectionType type,
  }) async {
    try {
      _validateAmount(amount);
      _validateString(studentID, "Student ID");
      await _repository.updateDuesBalance(
        docId: docId,
        studentID: studentID.trim(),
        amount: amount,
        isAddingDebt: isAddingDebt,
        type: type,
      );
      if (context.mounted) _showSuccess(context, "Dues updated successfully.");
    } catch (e) {
      debugPrint("FinanceController.updateDues Error: $e");
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> deletePayment({
    required BuildContext context,
    required String transId,
    required String studentID,
    required int amount,
    required CollectionType type,
  }) async {
    try {
      await _repository.deletePaymentRecord(transId, studentID, amount, type);
      if (context.mounted) _showSuccess(context, "Payment record deleted.");
    } catch (e) {
      debugPrint("FinanceController.deletePayment Error: $e");
      if (context.mounted) _showError(context, e.toString());
    }
  }

  // --- Savings Logic ---
  Future<void> updateSavings({
    required BuildContext context,
    required String studentID,
    required int amount,
    required bool isDeposit,
  }) async {
    try {
      _validateAmount(amount);
      _validateString(studentID, "Student ID");
      await _repository.updateSavingsBalance(studentID.trim(), amount, isDeposit);
      if (context.mounted) _showSuccess(context, "Savings updated.");
    } catch (e) {
      debugPrint("FinanceController.updateSavings Error: $e");
      if (context.mounted) _showError(context, e.toString());
    }
  }

  // --- Ledger Logic ---
  Future<void> addLedger({
    required BuildContext context,
    required DateTime date,
    required String subcommittee,
    required String purpose,
    required String type,
    required int amount,
  }) async {
    try {
      _validateAmount(amount);
      _validateString(subcommittee, "Subcommittee");
      _validateString(purpose, "Purpose");
      _validateString(type, "Type");
      await _repository.addLedgerEntry(
        date: date,
        subcommittee: subcommittee.trim(),
        purpose: purpose.trim(),
        type: type.trim(),
        amount: amount,
      );
      if (context.mounted) _showSuccess(context, "Ledger entry added.");
    } catch (e) {
      debugPrint("FinanceController.addLedger Error: $e");
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> deleteLedger({
    required BuildContext context,
    required String docId,
  }) async {
    try {
      await _repository.deleteLedgerEntry(docId);
      if (context.mounted) _showSuccess(context, "Ledger entry deleted.");
    } catch (e) {
      debugPrint("FinanceController.deleteLedger Error: $e");
      if (context.mounted) _showError(context, e.toString());
    }
  }

  // --- Purchase Logic ---
  Future<void> approvePurchase({
    required BuildContext context,
    required String docId,
  }) async {
    try {
      await _repository.approvePurchaseRequest(docId);
      if (context.mounted) _showSuccess(context, "Request approved.");
    } catch (e) {
      debugPrint("FinanceController.approvePurchase Error: $e");
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> rejectPurchase({
    required BuildContext context,
    required String docId,
    String? reason,
  }) async {
    try {
      await _repository.rejectPurchaseRequest(docId, reason);
      if (context.mounted) _showSuccess(context, "Request rejected.");
    } catch (e) {
      debugPrint("FinanceController.rejectPurchase Error: $e");
      if (context.mounted) _showError(context, e.toString());
    }
  }

  Future<void> deletePurchase({
    required BuildContext context,
    required String docId,
  }) async {
    try {
      await _repository.deletePurchaseRequest(docId);
      if (context.mounted) _showSuccess(context, "Request deleted.");
    } catch (e) {
      debugPrint("FinanceController.deletePurchase Error: $e");
      if (context.mounted) _showError(context, e.toString());
    }
  }

  // --- Settings Logic ---
  Stream<Map<String, dynamic>> get unionSettingsStream =>
      _repository.getUnionSettingsStream();

  Future<void> updateUnionDueAmount(int amount) async {
    await _repository.updateUnionDueAmount(amount);
  }
}
