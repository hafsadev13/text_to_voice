Voice Speaker - Flutter TTS App

A beautiful and feature-rich Text-to-Speech (TTS) application built with Flutter that supports multiple languages and voice genders with an elegant UI design.

Features:

Multi-language Support: English, French, Spanish, German, Italian, and Arabic
Voice Gender Selection: Switch between male and female voices
Modern UI: Beautiful gradient design with smooth animations
Real-time Status: Live feedback on speech status and voice availability
Responsive Design: Optimized for different screen sizes
Smart Voice Detection: Automatic categorization of available voices by gender

Setup Instructions:

=> Prerequisites:

Flutter SDK (>=3.0.0)
Dart SDK (>=2.17.0)
Android Studio / VS Code
Physical device or emulator (recommended: physical device for better TTS experience)

=> Dependencies:

Add these dependencies to your pubspec.yaml:
flutter_tts: ^4.2.3
google_fonts: ^6.2.1

Installation Steps:

Clone the repository
Install dependencies: flutter pub get
Run the app: flutter run

Usage

Select Language: Choose from 5 supported languages using the dropdown
Choose Voice Gender: Toggle between male and female voices
Enter Text: Type the text you want to be spoken
Play: Press the play button to start text-to-speech
Stop: Press the stop button to halt speech

Known Limitations & Assumptions:

=> Device-Specific Limitations

Voice availability varies by device: Not all devices have both male and female voices for every language
German voices: Most devices only provide male German voices
Italian voices: Most devices only provide female Italian voices
Offline functionality: App works offline once voices are downloaded to the device

=> Technical Assumptions

Flutter TTS Plugin: Relies on platform-specific TTS engines (Android TTS, iOS Speech Synthesis)
Voice Quality: Voice quality depends on the device's built-in TTS engine
Language Support: Actual language support depends on what's installed on the user's device
Network: Initial voice downloads may require internet connection on some devices

ScreenRecording:


Note: For the best experience, test the app on physical devices as TTS functionality is limited on emulators.
