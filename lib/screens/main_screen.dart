import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'sign_recognition_screen.dart';
import 'text_to_sign_screen.dart';
import 'live_captions_screen.dart';
import 'learning_center_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final pages = const [
    DashboardScreen(),
    SignRecognitionScreen(),
    TextToSignScreen(),
    LiveCaptionsScreen(),
    LearningCenterScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.front_hand), label: "Detect"),
          BottomNavigationBarItem(icon: Icon(Icons.text_fields), label: "Text→Sign"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Captions"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Learn"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
