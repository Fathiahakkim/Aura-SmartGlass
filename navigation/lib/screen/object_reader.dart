import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import '../main.dart';


class ObjectReaderScreen extends StatefulWidget {
  @override
  _ObjectReaderScreenState createState() => _ObjectReaderScreenState();
}

class _ObjectReaderScreenState extends State<ObjectReaderScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FlutterTts _flutterTts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();

  String userId = FirebaseAuth.instance.currentUser?.uid ?? "debugUser";
  String detectedObject = "";
  String translatedText = "";
  String userLanguage = "en"; // Default language

  @override
  void initState() {
    super.initState();
    _fetchUserLanguage();
    _listenForObjects();
    _speakWelcomeMessage(); // 🔹 Say welcome instructions when the app starts
  }

  // 🔹 Language Mapping (Firebase → Google Translate + TTS)
  Map<String, String> languageMap = {
    "English": "en",
    "Malayalam": "ml",
    "Spanish": "es",
    "French": "fr",
    "Hindi": "hi",
    "German": "de",
    "Tamil": "ta",
    "Arabic": "ar",
    "Chinese": "zh",
  };

  // 🔹 Fetch user's preferred language from Firebase
  void _fetchUserLanguage() {
    _dbRef.child("users/$userId/language").onValue.listen((event) async {
      if (event.snapshot.exists) {
        String newLanguage = event.snapshot.value.toString();
        String languageCode = languageMap[newLanguage] ?? "en";

        if (languageCode.isNotEmpty && languageCode != userLanguage) {
          setState(() {
            userLanguage = languageCode;
          });
          await _initializeTTS();
        }
      }
    });
  }

  // 🔹 Listen for detected objects from Firebase
  void _listenForObjects() {
    _dbRef.child("smart_glasses").onValue.listen((event) async {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};

        // Extract detected objects and recognized faces
        String detectedObjects = data["detected_objects"]?.toString() ?? "";
        String recognizedFaces = data["recognized_faces"]?.toString() ?? "";

        // 🔹 Combine results if both are detected
        String detected = "";
        if (detectedObjects.isNotEmpty && recognizedFaces.isNotEmpty) {
          detected = "$detectedObjects and $recognizedFaces"; // Example: "Car and Person"
        } else if (detectedObjects.isNotEmpty) {
          detected = detectedObjects;
        } else if (recognizedFaces.isNotEmpty) {
          detected = recognizedFaces;
        }

        if (detected.isNotEmpty && detected != detectedObject) {
          setState(() {
            detectedObject = detected;
          });

          // 🔹 Translate and speak the combined text
          await _translateText(detectedObject);
        }
      }
    });
  }




  // 🔹 Translate detected text using Google Translator
  Future<void> _translateText(String text) async {
    try {
      Translation translation = await _translator.translate(text, to: userLanguage);
      setState(() {
        translatedText = translation.text;
      });

      await _speakText(translatedText);
    } catch (e) {
      print("❌ Translation Error: $e");
    }
  }

  // 🔹 Initialize TTS settings
  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage(userLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  // 🔹 Speak the translated text
  Future<void> _speakText(String text) async {
    if (text.isNotEmpty) {
      try {
        await _flutterTts.setLanguage(userLanguage);
        await _flutterTts.stop();
        await _flutterTts.speak(text);
      } catch (e) {
        print("❌ Error in TTS: $e");
      }
    }
  }

  // 🔹 Speak welcome instructions
  Future<void> _speakWelcomeMessage() async {
    String welcomeMessage = "Object detection started. Press the stop button to exit.";
    await _flutterTts.speak(welcomeMessage);
  }

  // 🔹 Stop detection and return to home
  void _stopDetection() async {
    await _flutterTts.speak("Stopping detection. Returning to home.");

    // ✅ Send "Stop" command to Firebase
    _dbRef.child("commands/$userId/command").set("q");

    await Future.delayed(Duration(seconds: 2));

    // ✅ Navigate back to `main.dart`
    if (mounted) {
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (_) => VoiceControlledScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Object Detection Active",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Detected: $detectedObject",
              style: TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Translated: $translatedText",
              style: TextStyle(color: Colors.orangeAccent, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _stopDetection, // 🔹 Button will stop detection immediately
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      spreadRadius: 4,
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Text(
                  "🛑 Stop Detection",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
