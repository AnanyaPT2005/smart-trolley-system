import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'barcode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrolleySelectionPage extends StatefulWidget {
  @override
  _TrolleySelectionPageState createState() => _TrolleySelectionPageState();
}

class _TrolleySelectionPageState extends State<TrolleySelectionPage> {
  List<String> activeTrolleys = [];

  final String baseUrl = "http://192.168.1.6:5000"; // 🔁 change this
  final String userId = "k0QikpYBAenGL7KaEmCR"; // 🔒 hardcoded for now

  @override
  void initState() {
    super.initState();
    fetchActiveTrolleys();
  }

  Future<void> fetchActiveTrolleys() async {
    try {
      print("Calling: $baseUrl/api/active-trolleys");

      final response = await http.get(
        Uri.parse("$baseUrl/api/active-trolleys"),
      );

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          activeTrolleys = List<String>.from(
            json.decode(response.body).map((e) => e.toLowerCase()),
          );
        });
      }
    } catch (e) {
      print("FETCH ERROR: $e"); // 🔥 THIS is what you're missing
    }
  }

  List<String> allTrolleys = ["t1", "t2", "t3", "t4", "t5"];

  Future<void> createSession(String trolleyId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/create-session"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"trolley_id": trolleyId, "user_id": userId}),
    );
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      String sessionId = data["session_id"]; // ✅ EXTRACT from backend

      await saveSession(sessionId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodePage(sessionId: sessionId),
        ),
      );
    } else {
      print("Error creating session");
    }
  }

  Future<void> saveSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_id', sessionId);
  }

  @override
  Widget build(BuildContext context) {
    // fetchActiveTrolleys();
    List<String> availableTrolleys = allTrolleys
        .where((t) => !activeTrolleys.contains(t))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Select Trolley")),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: availableTrolleys.map((trolley) {
          return ElevatedButton(
            onPressed: () => createSession(trolley),
            child: Text(trolley.toUpperCase()),
          );
        }).toList(),
      ),
    );
  }
}
