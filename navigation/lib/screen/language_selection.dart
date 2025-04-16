import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_commands.dart';

class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String userId = FirebaseAuth.instance.currentUser?.uid ?? "debugUser";
  bool _isListening = false;
  String selectedLanguage = "";

  List<String> availableLanguages = ["English", "Spanish", "French", "German", "Malayalam"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptLanguageSelection());
  }

  void _promptLanguageSelection() async {
    await _flutterTts.speak("Please say your preferred language: English, Spanish, French, German, or Malayalam.");
    await Future.delayed(Duration(seconds: 10));
    _startListeningForLanguage();
  }

  void _startListeningForLanguage() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          String spokenLanguage = result.recognizedWords.toLowerCase();
          print("Recognized Language: $spokenLanguage");

          if (spokenLanguage.isNotEmpty) {
            String matchedLanguage = availableLanguages.firstWhere(
                    (lang) => lang.toLowerCase() == spokenLanguage,
                orElse: () => ""
            );

            if (matchedLanguage.isNotEmpty) {
              _speech.stop().then((_) => _confirmLanguage(matchedLanguage));
            }
          }
        },
        listenFor: Duration(seconds: 110), // ⬅️ Increase listening duration to 60 seconds
        pauseFor: Duration(seconds: 5),   // ⬅️ Allows a pause before stopping
      );
    }
  }

  void _confirmLanguage(String language) async {
    setState(() => selectedLanguage = language);
    print("✅ Confirming Language: $language");
    await _flutterTts.speak("You selected $language. Say 'ok' to confirm.");
    await Future.delayed(Duration(seconds: 6));

    _startListeningForConfirmation();
  }

  void _startListeningForConfirmation() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) async {
          String confirmation = result.recognizedWords.toLowerCase();
          print("Confirmation Received: $confirmation");

          if (confirmation == "ok" || confirmation == "okey" || confirmation == "okay") {
            await _speech.stop();
            print("✅ Confirmation received, storing language...");
            await _saveLanguageToFirebase(selectedLanguage);
          }
        },
        listenFor: Duration(seconds: 90), // ⬅️ Increase listening duration to 60 seconds
        pauseFor: Duration(seconds: 5),   // ⬅️ Allows a pause before stopping

      );
    } else {
      print("❌ Speech recognition unavailable, retrying...");
      await Future.delayed(Duration(seconds: 2));
      _startListeningForConfirmation();
    }
  }

  Future<void> _saveLanguageToFirebase(String language) async {
    if (language.isEmpty) {
      print("❌ Error: Language is empty. Not saving to Firebase.");
      return;
    }
    try {
      print("🔵 Saving language to Firebase: $language...");
      await _dbRef.child("users/$userId").update({"language": language});
      print("✅ Language stored successfully!");

      await _flutterTts.speak("Language set to $language. Redirecting...");
      await Future.delayed(Duration(seconds: 4));

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VoiceCommandsScreen()));
      }
    } catch (e) {
      print("❌ Error storing language: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          _isListening ? "Listening for language selection..." : "Say your preferred language",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}