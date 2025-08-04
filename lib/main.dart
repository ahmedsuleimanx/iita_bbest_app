import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'core/app.dart';
import 'core/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize SharedPreferences
  await _initializeServices();
  
  runApp(
    const ProviderScope(
      child: IITABBestApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  // Initialize SharedPreferences
  await SharedPreferences.getInstance();
  
  // Add any other service initializations here
}
