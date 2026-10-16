// lib/features/finance/data/repositories/finance_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum CollectionType { union, store }

abstract class FinanceRepository {
  // --- Dues & Payments (Union / Store) ---
  Stream<QuerySnapshot> getStudentsStream();
  Stream<QuerySnapshot> getPaymentHistoryStream(String studentID, CollectionType type);
  Future<void> updateDuesBalance({
    required String docId,
    required String studentID,
    required int amount,
    required bool isAddingDebt,
    required CollectionType type,
  });
  Future<void> deletePaymentRecord(String transId, String studentID, int amount, CollectionType type);

  // --- Savings / Treasury (Numbered Ledger) ---
  Stream<QuerySnapshot> getTreasuryStream();
  Stream<QuerySnapshot> getStudentSavingsHistory(String studentID);
  Future<void> updateSavingsBalance(String studentID, int amount, bool isDeposit);

  // --- Account Ledger (Aero Ledger) ---
  Stream<QuerySnapshot<Map<String, dynamic>>> getAeroLedgerStream();
  Future<void> addLedgerEntry({
    required DateTime date,
    required String subcommittee,
    required String purpose,
    required String type, // INCOME / EXPENSE
    required int amount,
  });
  Future<void> deleteLedgerEntry(String docId);

  // --- Purchase Requests ---
  Stream<QuerySnapshot> getPurchaseRequestsStream(String status);
  Future<void> approvePurchaseRequest(String docId);
  Future<void> rejectPurchaseRequest(String docId, String? reason);
  Future<void> deletePurchaseRequest(String docId);
}
