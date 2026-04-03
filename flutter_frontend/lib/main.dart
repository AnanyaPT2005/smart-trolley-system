// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'trolley_selection.dart';
// import 'barcode.dart';
// import 'user_cart.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // 🔥 get saved session
//   Future<String?> getSession() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('session_id');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Smart Trolley',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),

//       // ❗ we replace initialRoute with dynamic loading
//       home: FutureBuilder<String?>(
//         future: getSession(),
//         builder: (context, snapshot) {
//           // loading state
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }

//           final sessionId = snapshot.data;

//           // 🔥 decide start screen
//           if (sessionId != null) {
//             return UserCartPage(sessionId: sessionId);
//           } else {
//             return TrolleySelectionPage();
//           }
//         },
//       ),

//       // keep routes for navigation
//       routes: {
//         '/trolley': (context) => TrolleySelectionPage(),

//         // ❗ barcode route now expects arguments
//         '/barcode': (context) {
//           final args = ModalRoute.of(context)!.settings.arguments as String;
//           return BarcodePage(sessionId: args);
//         },
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'trolley_selection.dart';
import 'barcode.dart';
import 'user_cart.dart';
import 'config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 🔥 get active session from backend (WITH DEBUG)
  Future<String?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    print("🔍 Stored user_id: $userId");

    if (userId == null) {
      print("❌ No user_id found in SharedPreferences");
      return null;
    }

    try {
      final url = "${AppConfig.baseUrl}/get-user-session/$userId";
      print("🌐 Calling API: $url");

      final response = await http.get(Uri.parse(url));

      print("📡 Response status: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sessionId = data["session_id"];

        print("✅ Active session from backend: $sessionId");

        return sessionId;
      } else {
        print("❌ Backend returned non-200 status");
      }
    } catch (e) {
      print("🚨 ERROR fetching session: $e");
      return "ERROR"; // 🔥 special debug value
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Trolley',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      home: FutureBuilder<String?>(
        future: getActiveSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("⏳ Waiting for session...");
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final sessionId = snapshot.data;

          print("🎯 Final session निर्णय: $sessionId");

          // 🔥 handle error case
          if (sessionId == "ERROR") {
            return const Scaffold(
              body: Center(
                child: Text(
                  "⚠️ Cannot connect to backend\nCheck WiFi / Server",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // 🔥 normal flow
          if (sessionId != null && sessionId.trim().isNotEmpty) {
            print("➡️ Opening UserCartPage");
            return UserCartPage(sessionId: sessionId);
          } else {
            print("➡️ Opening TrolleySelectionPage");
            return TrolleySelectionPage();
          }
        },
      ),

      routes: {
        '/trolley': (context) => TrolleySelectionPage(),

        '/barcode': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return BarcodePage(sessionId: args);
        },
      },
    );
  }
}
