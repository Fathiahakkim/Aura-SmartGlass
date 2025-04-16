import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

class NavigationScreen extends StatefulWidget {
  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  final String userId = "userID"; // Replace with actual user ID

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    checkHomeLocation();
  }

  /// 🔹 **Check if Home Location Exists**
  void checkHomeLocation() async {
    DataSnapshot snapshot = await database.child("users/$userId/home_location").get();

    if (snapshot.exists && snapshot.value != null) {
      print("✅ Home location already set.");
      askUserToNavigateHome();
    } else {
      print("❌ Home location not set. Asking user to set it.");
      askToSetHomeLocation();
    }
  }

  /// 🔹 **Fetch Current Location from Firebase `/gps`**
  Future<Map<String, double>?> fetchCurrentLocation() async {
    try {
      DataSnapshot snapshot = await database.child("gps").get();

      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        double lat = (data['latitude'] as num).toDouble();
        double lon = (data['longitude'] as num).toDouble();
        return {"latitude": lat, "longitude": lon};
      } else {
        print("❌ No GPS data found!");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching current location: $e");
      return null;
    }
  }

  /// 🔹 **Ask User to Set Home Location**
  void askToSetHomeLocation() async {
    await _flutterTts.speak("Do you want to set this location as your home?");
    await Future.delayed(Duration(seconds: 3));
    startListeningForHomeSetup();
  }

  void startListeningForHomeSetup() async {
    if (!_isListening) {
      bool available = await _speech.initialize();

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) async {
            String command = val.recognizedWords.toLowerCase();
            if (command.contains("yes")) {
              await saveHomeLocation();
              askToStayOrHomeScreen(() => askToSetHomeLocation());
            } else {
              repeatQuestion(() => askToSetHomeLocation());
            }
            setState(() => _isListening = false);
          },
          listenFor: Duration(seconds: 15),
          partialResults: true,
        );
      }
    }
  }

  /// 🔹 **Save Current Location as Home**
  Future<void> saveHomeLocation() async {
    Map<String, double>? currentLoc = await fetchCurrentLocation();
    if (currentLoc != null) {
      await database.child("users/$userId/home_location").set({
        "latitude": currentLoc['latitude'],
        "longitude": currentLoc['longitude'],
      });
      await _flutterTts.speak("Your home location has been saved.");
    } else {
      print("❌ Error saving home location.");
    }
  }

  /// 🔹 **Ask User to Navigate Home**
  void askUserToNavigateHome() async {
    await _flutterTts.speak("Do you want to return home? navigate      or   say emergency if you need emergency assistance.   or   say back to return to home screen");
    await Future.delayed(Duration(seconds: 15));
    startListeningForNavigation();
  }

  void startListeningForNavigation() async {
    if (!_isListening) {
      bool available = await _speech.initialize();

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          onResult: (val) async {
            String command = val.recognizedWords.toLowerCase().trim();

            print("🔍 Detected command: $command");

            if (command == "navigate") {
              _speech.stop(); // Stop listening before navigating
              navigateToHome();
            } else if (command == "emergency") {
              _speech.stop(); // Stop listening before handling emergency
              handleEmergency();
            }else if (command == "back") {
              _speech.stop(); // Stop listening before navigating
              goback();
            }
            else {
              repeatQuestion(() => askUserToNavigateHome());
            }

            setState(() => _isListening = false);
          },
          listenFor: Duration(seconds: 90),
          partialResults: false, // ✅ Only accept final results
        );
      }
    }
  }


  /// 🔹 **Handle Emergency Call**
  void handleEmergency() async {
    _speech.stop(); // ✅ Stop listening to avoid multiple actions

    await database.child("emergency_status").set({
      "status": "help",
      "timestamp": DateTime.now().toString()
    });
    makeEmergencyCall();
    Future.delayed(Duration(seconds: 120), () async {
      await database.child("emergency_status").remove();
    });
  }

  /// 🔹 **Make an Emergency Call**
  void makeEmergencyCall() async {
    await database.child("emergency_status").set({
      "status": "help",
      "timestamp": DateTime.now().toString()
    });

    const String emergencyNumber = "+917592894755";
    bool? res = await FlutterPhoneDirectCaller.callNumber(emergencyNumber);
    if (res == true) {
      print("📞 Emergency call placed successfully!");
      exit(0);
    } else {
      print("❌ Could not place emergency call.");
    }
  }

  /// 🔹 **Navigate to Home in Google Maps**



  Future<void> navigateToHome() async {
    // ✅ 1. Get the user's current location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("❌ Error getting current location: $e");
      await _flutterTts.speak("Error! Could not fetch your current location.");
      return;
    }

    double currentLat = position.latitude;
    double currentLon = position.longitude;

    // ✅ 2. Get the predefined home location from Firebase
    DataSnapshot snapshot = await database.child("users/$userId/home_location").get();

    if (snapshot.exists && snapshot.value != null) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

      if (!(data.containsKey('latitude') && data.containsKey('longitude'))) {
        print("❌ Home location data is incomplete.");
        await _flutterTts.speak("Error! Home location is not set properly. Please update it.");
        return;
      }

      double homeLat = (data['latitude'] as num).toDouble();
      double homeLon = (data['longitude'] as num).toDouble();

      // ✅ 3. Open Google Maps with both start & destination locations
      String googleMapsUrl = Uri.encodeFull(
          "https://www.google.com/maps/dir/?api=1"
              "&origin=$currentLat,$currentLon"
              "&destination=$homeLat,$homeLon"
              "&travelmode=walking"
              "&dir_action=navigate"
      );

      Uri mapsUri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(mapsUri)) {
        await _flutterTts.speak("Starting navigation to your home location.");
        await Future.delayed(Duration(seconds: 2)); // Ensure speech completes
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        exit(0); // ✅ Close app after launching Google Maps
      } else {
        print("❌ Could not launch Google Maps.");
        await _flutterTts.speak("Error! Unable to open Google Maps.");
      }
    } else {
      print("❌ No home location found!");
      await _flutterTts.speak("Home location is not set. Please set it first.");
    }
  }





  /// 🔹 **Ask User to Stay or Return to Home Screen**
  void askToStayOrHomeScreen(Function retryAction) async {
    await _flutterTts.speak("Do you want to stay or go back to the home screen?");
    await Future.delayed(Duration(seconds: 3));
    listenForStayOrHomeScreen(retryAction);
  }

  void listenForStayOrHomeScreen(Function retryAction) async {
    if (!_isListening) {
      bool available = await _speech.initialize();

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) async {
            String command = val.recognizedWords.toLowerCase();
            if (command.contains("stay")) {
              print("✅ User chose to stay.");
            } else if (command.contains("home")) {
              Navigator.pop(context);
            } else {
              repeatQuestion(() => askToStayOrHomeScreen(retryAction));
            }
            setState(() => _isListening = false);
          },
          listenFor: Duration(seconds: 95),
          partialResults: true,
        );
      }
    }
  }
  void goback() async {
    await _flutterTts.speak("Stopping detection. Returning to home.");

    // ✅ Send "Stop" command to Firebase


    await Future.delayed(Duration(seconds: 2));

    // ✅ Navigate back to `main.dart`
    if (mounted) {
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (_) => VoiceControlledScreen()));
    }
  }
  /// 🔹 **Repeat Question if No Response**
  void repeatQuestion(Function retryAction) async {
    await _flutterTts.speak("I didn't hear you. Please answer again.");
    await Future.delayed(Duration(seconds: 2));
    _speech.stop(); // ✅ Ensure previous listening session is stopped

    retryAction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Navigation Screen")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Fetching location..."),
          ],
        ),
      ),
    );
  }


}
