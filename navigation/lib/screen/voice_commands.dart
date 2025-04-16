import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'object_reader.dart';
import 'package:flutter/services.dart';

class VoiceCommandsScreen extends StatefulWidget {
  @override
  _VoiceCommandsScreenState createState() => _VoiceCommandsScreenState();
}

class _VoiceCommandsScreenState extends State<VoiceCommandsScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final GoogleTranslator _translator = GoogleTranslator();

  String userId = FirebaseAuth.instance.currentUser?.uid ?? "debugUser";
  bool _isListening = false;
  String recognizedText = "";
  String selectedLanguage = "";
  Map<String, String> commandTranslations = {};

  @override
  void initState() {
    super.initState();
    _getUserLanguage();
  }

  // 🔹 Fetch user's preferred language from Firebase
  void _getUserLanguage() async {
    DatabaseEvent event = await _dbRef.child("users/$userId/language").once();
    if (event.snapshot.exists) {
      setState(() {
        selectedLanguage = event.snapshot.value.toString();
      });

      print("✅ User's Language: $selectedLanguage");

      String startCommand = _getCommandTranslation("start", selectedLanguage);
      String stopCommand = _getCommandTranslation("stop", selectedLanguage);

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak("Say '$startCommand' or '$stopCommand' in $selectedLanguage.");
      await _flutterTts.awaitSpeakCompletion(true);

      Future.delayed(Duration(seconds: 4), () => _startListening());
    }
  }

  // 🔹 Map language names to language codes
  String _getLanguageCode(String language) {
    Map<String, String> languageCodes = {
      "English": "en",
      "Spanish": "es",
      "French": "fr",
      "German": "de",
      "Malayalam": "ml",
    };
    return languageCodes[language] ?? "en";  // Default to English
  }

  // 🔹 Translations for "Start" and "Stop"
  String _getCommandTranslation(String command, String language) {
    Map<String, Map<String, String>> translations = {
      "start": {
        "English": "Start",
        "Spanish": "Iniciar",
        "French": "Commencer",
        "German": "Starten",
        "Malayalam": "Thudanguka", // ✅ Added "Thudanguka" for "Start"
      },
      "stop": {
        "English": "Stop",
        "Spanish": "Detener",
        "French": "Arrêter",
        "German": "Stoppen",
        "Malayalam": "Nirthuka" // ✅ Stop remains the same
      }
    };

    return translations[command]?[language] ?? command; // Default to original command
  }


  // 🔹 Start listening for voice commands
  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print("🎙 Speech Status: $status");
        if (status == "notListening" && _isListening) {
          Future.delayed(Duration(seconds: 1), () => _startListening()); // Restart listening
        }
      },
      onError: (error) {
        print("❌ Speech Error: $error");
        Future.delayed(Duration(seconds: 2), () => _startListening()); // Restart on error
      },
    );

    if (available) {
      if (mounted) setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            recognizedText = result.recognizedWords.toLowerCase().trim();
          });
          print("🎤 Recognized: $recognizedText");
          _processCommand(recognizedText);
        },
        listenFor: Duration(seconds: 90), // Max supported duration
        pauseFor: Duration(seconds: 5),   // Allows short pauses
        cancelOnError: false,
        partialResults: false,
      );
    } else {
      print("❌ Speech Recognition Not Available");
    }
  }


  // 🔹 Process voice commands ("Start" or "Stop") with translation
  void _processCommand(String command) async {
    print("🔍 User Said: '$command'");

    String startCommand = _getCommandTranslation("start", selectedLanguage).toLowerCase();
    String stopCommand = _getCommandTranslation("stop", selectedLanguage).toLowerCase();

    // ✅ Recognize both "Thudanguka" and "Aarambhikkuka" in Malayalam
    List<String> startCommandsMalayalam = ["thudanguga", "tu danguga","to tango car","'tu danguga","to dangu","thodanga","tadanga"];

    // ✅ Translate to English if needed
    if (selectedLanguage != "English") {
      Translation translatedCommand = await _translator.translate(command, from: _getLanguageCode(selectedLanguage), to: "en");
      command = translatedCommand.text.toLowerCase().trim();
      print("🌍 Translated Command: '$command'");
    }

    // ✅ Recognize "Start" command
    if (command == "start" || command == startCommand || startCommandsMalayalam.contains(command)) {
      print("✅ 'Start' command recognized! Sending to Firebase...");
      await _sendCommandToFirebase("s");

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak("Starting object detection.");
      await _flutterTts.awaitSpeakCompletion(true);

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ObjectReaderScreen()),
        );
      });

      // ✅ Recognize "Stop" command
    } else if (command == "stop" || command == stopCommand) {
      print("✅ 'Stop' command recognized! Sending to Firebase...");
      await _sendCommandToFirebase("q");

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak("Stopping detection.");
      await _flutterTts.awaitSpeakCompletion(true);
      Future.delayed(Duration(seconds: 3), () {
        SystemNavigator.pop();
      });

    } else {
      print("❌ Unrecognized command: '$command'");
      _speech.stop();
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak("Command not recognized. Please say $startCommand or $stopCommand.");
      await _flutterTts.awaitSpeakCompletion(true);

      Future.delayed(Duration(seconds: 5), () => _startListening());
    }
  }

  // 🔹 Send command ("s" for Start, "q" for Stop) to Firebase
  Future<void> _sendCommandToFirebase(String command) async {
    print("🔹 Sending command to Firebase: $command");

    try {
      await _dbRef.child("commands/$userId").set({"command": command});
      print("✅ Firebase updated successfully with command: $command");

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.speak("Command sent successfully.");
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      print("❌ Firebase update failed: $e");
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
              "Voice Control",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              recognizedText,
              style: TextStyle(color: Colors.greenAccent, fontSize: 18),
            ),
            SizedBox(height: 40),
            GestureDetector(
              onTap: _startListening,
              child: Icon(Icons.mic, color: Colors.blue, size: 100),
            ),
          ],
        ),
      ),
    );
  }
}
