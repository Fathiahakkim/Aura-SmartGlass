import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'screen/object_detection_screen.dart';
import 'services/firebase_services.dart';
import 'services/counter_manager.dart';
import 'dart:io';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VoiceControlledScreen(),
    );
  }
}

class VoiceControlledScreen extends StatefulWidget {
  @override
  _VoiceControlledScreenState createState() => _VoiceControlledScreenState();
}

class _VoiceControlledScreenState extends State<VoiceControlledScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _recognizedText = "";

  int _listenAttempts = 0; // Counter for listening attempts
  final int _maxAttempts = 6; // Maximum attempts before exiting

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);

    _speakWelcomeMessage();
  }

  Future<void> _speakWelcomeMessage() async {
    await _flutterTts.speak("Welcome to Aura. Say 'Detect' for Object Detection or 'Navigation' for Navigation Assistance.");
    await Future.delayed(Duration(seconds: 10)); // Wait before starting
    _startListening();
  }
  void _startListening() async {
    if (CounterManager.isMaxAttemptsReached()) {
      print("Max attempts reached. Exiting...");
      await _flutterTts.speak("No response detected. Exiting the application.");
      await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context); // Close the app
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print("Speech Status: $status");
          if (status == "notListening") {
            Future.delayed(Duration(seconds: 1), () {
              if (!_isListening) {
                _startListening();
              }
            });
          }
        },
        onError: (error) {
          print("Speech Error: ${error.errorMsg}");
          if (error.errorMsg.contains("error_no_match")) {
            print("No speech detected, retrying...");
            Future.delayed(Duration(seconds: 1), () {
              setState(() {
                _isListening = false; // Reset
              });
              _startListening(); // Force retry
            });
          }
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          CounterManager.incrementAttempt();
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
            });
            print("Recognized: $_recognizedText");
            _processCommand(_recognizedText);
          },
        );

        print("Listening attempt: ${CounterManager.listenAttempts}");
      } else {
        print("Speech recognition not available.");
      }
    }
  }

  void _processCommand(String command) async {
    _speech.stop(); // ✅ Stop listening immediately
    setState(() => _isListening = false); // ✅ Ensure listening is stopped

    String cleanedCommand = command.trim().toLowerCase();
    print("Processing Command: $cleanedCommand");

    if (cleanedCommand == "detect") {
      print("Command Recognized: Object Detection");

      await _flutterTts.speak("Opening Object Detection.");
      await Future.delayed(Duration(seconds: 2)); // ✅ Ensure speech completes

      if (mounted) {
        await Future.delayed(Duration(milliseconds: 800)); // ✅ Allow stop action to take effect
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthCheck()),
        );
      }

      return; // ✅ Exit function to prevent retries
    }
    else if (cleanedCommand == "navigation") {
      print("Command Recognized: Navigation");

      await _flutterTts.speak("Opening Navigation Assistance.");
      await Future.delayed(Duration(seconds: 2)); // ✅ Ensure speech completes

      if (mounted) {
        await Future.delayed(Duration(milliseconds: 800)); // ✅ Allow stop action to take effect
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationScreen()),
        );
      }
      return; // ✅ Exit function to prevent retries
    }else if (cleanedCommand == "exit") {
      print("Command Recognized: Exit");

      await _flutterTts.speak("Exiting the app.");
      await Future.delayed(Duration(seconds: 2)); // ✅ Ensure speech completes
      //exit(0);// Close the app
      SystemNavigator.pop();
      return;
    }

    // ✅ If command is unrecognized, provide feedback once without repetition
    print("Command Unrecognized. Asking user to repeat.");

    await _flutterTts.speak("Please say again.");
    await Future.delayed(Duration(seconds: 1)); // ✅ Prevent overlap

    _startListening();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // High-contrast UI for accessibility
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Select an option using voice command",
            style: TextStyle(color: Colors.white, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOption("Detect", Icons.camera_alt, Colors.blue),
              SizedBox(width: 30),
              _buildOption("Navigation", Icons.directions, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 50, color: Colors.white),
        ),
        SizedBox(height: 10),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }
}



