Aura: Automated User Recognition and Assistance
Aura is an AI-powered smart glass system designed to assist visually impaired individuals in understanding their surroundings through real-time object detection, face recognition, multilingual narration, and navigation. The system integrates a voice-controlled Android app and ESP32-CAM hardware, creating an affordable and user-friendly wearable assistive device.

Project Overview
Aura addresses key challenges faced by visually impaired individuals:

Difficulty recognizing obstacles and navigating unfamiliar environments
Limited accessibility in existing tools
Need for affordable, multilingual, hands-free assistance
Key Features
Real-Time Object Detection using ESP32-CAM and YOLOv5
Face Recognition for familiar people
Voice-Controlled Android App (built with Flutter)
GPS Navigation via Google Maps API
Text-to-Speech Feedback using eSpeak and Android TTS
Cloud Integration with Firebase for object label storage
Emergency SMS & Call Feature using Twilio API
Multilingual Narration for diverse user support
Battery-Powered Smart Glass with 3–4 hours runtime
Android App Features
Full voice interaction using Google Speech-to-Text (STT)
Detect, navigate, and emergency commands recognized via voice
Bluetooth communication with hardware
Visual UI with multilingual support and feedback
Technologies Used
Software	Hardware
Flutter (Android App)	ESP32-CAM
OpenCV + YOLOv5 (PyTorch)	GPS Module
Firebase (Cloud DB)	Li-ion Battery + Booster Module
eSpeak / Android TTS	On/Off Button
Twilio API (Emergency)	
Project Structure
Aura-Smart-Glass/
├── android_app/              # Android Studio (Flutter) source code
├── esp32_cam_code/           # (To be added) ESP32-CAM Arduino code
├── images/                   # UI Screenshots and circuit photos
├── demo_video/               # (Optional) Link or file
└── README.md                 # Project documentation
System Architecture
Input: Voice commands from user → STT → Android App
Processing:
Object detection / face recognition by ESP32-CAM using YOLOv5
Navigation using GPS + Google Maps
Firebase stores label & location
Output:
TTS provides audio feedback
Navigation launched on phone
Emergency call and SMS sent if triggered
Results
Object Detection Accuracy: 85%
Face Recognition Accuracy: 100%
Navigation Accuracy: 100%
Emergency Call & SMS: 100% success rate
Voice Command Recognition: 75% accuracy
Battery Backup: 3–4 hours continuous use
Developed By
Department of Information Technology
Government Engineering College, Palakkad
Project Date: March 27, 2025

Team Members:

Fathima A
Al Thanzeera Basheer
Jemsheena M
Aparna Sabu
Project Guide: Dr. Silpa Sangeeth L R

Future Enhancements
Add obstacle distance estimation with ultrasonic sensors
Implement on-device inference for real-time processing
Add staircase and tactile paving detection
Integrate LIDAR or infrared for better indoor support
Add vibration/tactile feedback for silent mode
License
This project is licensed under the MIT License.

Appreciation
“The Multilingual Smart Glasses provide a reliable, real-time assistive solution for visually impaired individuals. This project demonstrates practical integration of AI, embedded systems, and voice control for accessibility enhancement.”
