import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Garden App',
      home: const HomePage(),
    );
  }
}

// A temporary Home Page to demonstrate navigation to the subpage
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigation to the GardenPage subpage
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GardenPage()),
            );
          },
          child: const Text('Open Garden Subpage'),
        ),
      ),
    );
  }
}

// The requested subpage class
class GardenPage extends StatelessWidget {
  const GardenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar automatically provides a "Back" button for subpages
      appBar: AppBar(
        title: const Text('Garden Page'),
      ),
      // Simple, empty container as requested
      body: Container(
        color: Colors.white,
      ),
    );
  }
}