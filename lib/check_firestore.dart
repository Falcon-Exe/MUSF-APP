import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  debugPrint("--- Firestore Student Check ---");

  // Try to find any admin
  final snapshot = await FirebaseFirestore.instance
      .collection('students')
      .get();

  debugPrint("Found ${snapshot.docs.length} students.");

  for (var doc in snapshot.docs) {
    var data = doc.data();
    if (data['isAdmin'] != null || data['admin'] != null) {
      debugPrint("Doc ID: ${doc.id}");
      debugPrint("Data: $data");
    }
  }

  debugPrint("--- End Check ---");
}
