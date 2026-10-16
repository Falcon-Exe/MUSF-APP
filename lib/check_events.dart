import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final snapshot = await FirebaseFirestore.instance.collection('literary_events').get();
  debugPrint("Found ${snapshot.docs.length} literary events.");
}
