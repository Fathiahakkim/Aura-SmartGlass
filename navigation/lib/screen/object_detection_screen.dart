import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'language_selection.dart';
import 'voice_commands.dart';

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingUI(); // Separate UI method
        }

        if (snapshot.hasData) {
          return VoiceCommandsScreen();
        } else {
          return LanguageSelectionScreen();
        }
      },
    );
  }

  /// **UI Design for Loading Screen**
  Widget _buildLoadingUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 20),
            Text(
              "Checking authentication...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}


Widget _buildLoadingUI() {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 20),
          Text(
            "Checking authentication...",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    ),
  );
}

