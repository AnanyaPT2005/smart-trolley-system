

// import 'package:flutter/material.dart';
// import 'trolley_selection.dart';
// import 'barcode.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Smart Trolley',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),

//       // 🔥 ADD THIS
//       initialRoute: '/',
//       routes: {
//         '/': (context) => TrolleySelectionPage(),
//         '/barcode': (context) => BarcodePage(),
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trolley_selection.dart';
import 'barcode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 🔥 get saved session
  Future<String?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_id');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Trolley',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      // ❗ we replace initialRoute with dynamic loading
      home: FutureBuilder<String?>(
        future: getSession(),
        builder: (context, snapshot) {

          // loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final sessionId = snapshot.data;

          // 🔥 decide start screen
          if (sessionId != null) {
            return BarcodePage(sessionId: sessionId);
          } else {
            return TrolleySelectionPage();
          }
        },
      ),

      // keep routes for navigation
      routes: {
        '/trolley': (context) => TrolleySelectionPage(),

        // ❗ barcode route now expects arguments
        '/barcode': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return BarcodePage(sessionId: args);
        },
      },
    );
  }
}