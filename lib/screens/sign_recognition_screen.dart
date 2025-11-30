import 'package:flutter/material.dart';

class SignRecognitionScreen extends StatelessWidget {
  const SignRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Recognition")),
      body: const Center(
        child: Text(
          "Camera Placeholder\n(ML model will be integrated later)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
