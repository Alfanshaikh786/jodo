import 'package:flutter/material.dart';

class TextToSignScreen extends StatelessWidget {
  const TextToSignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Text to Sign Animation")),
      body: const Center(
        child: Text(
          "Enter text → Show sign animation\n(Coming soon)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
