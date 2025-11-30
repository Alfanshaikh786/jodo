import 'package:flutter/material.dart';

class LiveCaptionsScreen extends StatelessWidget {
  const LiveCaptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Captions")),
      body: const Center(
        child: Text(
          "Speech-to-text live captions\n(Coming soon)",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
