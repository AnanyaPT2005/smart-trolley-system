// import 'package:flutter/material.dart';
// import 'user_cart.dart';

// class BarcodePage extends StatelessWidget {
//   final String sessionId; // ✅ add this

//   const BarcodePage({required this.sessionId, super.key}); // ✅ constructor

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Barcode")),

//       body: Center(
//         child: Text(
//           "Barcode Page\nSession: $sessionId", // for testing
//           textAlign: TextAlign.center,
//           style: const TextStyle(fontSize: 24),
//         ),
//       ),

//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SizedBox(
//           height: 60,
//           child: ElevatedButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       UserCartPage(sessionId: sessionId), // ✅ pass forward
//                 ),
//               );
//             },
//             child: const Text(
//               "Go to Cart",
//               style: TextStyle(fontSize: 18),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'user_cart.dart';

class BarcodePage extends StatefulWidget {
  final String sessionId;

  const BarcodePage({required this.sessionId, super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  bool isScanning = true;

  final String baseUrl = "http://192.168.1.6:5000"; // 🔁 change if needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Products")),

      body: Column(
        children: [
          // 🔍 CAMERA SCANNER
          Expanded(
            flex: 3,
            child: MobileScanner(
              onDetect: (barcodeCapture) async {
                if (!isScanning) return;

                final barcode = barcodeCapture.barcodes.first;
                final String? code = barcode.rawValue;

                if (code != null) {
                  setState(() {
                    isScanning = false;
                  });

                  try {
                    final response = await http.post(
                      Uri.parse("$baseUrl/add-item"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "barcode": code,
                        "session_id": widget.sessionId,
                      }),
                    );

                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Added: $code")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to add item")),
                      );
                    }
                  } catch (e) {
                    print("ERROR: $e");
                  }

                  // ⏳ allow next scan after delay
                  Future.delayed(const Duration(seconds: 2), () {
                    setState(() {
                      isScanning = true;
                    });
                  });
                }
              },
            ),
          ),

          // 🔽 BOTTOM SECTION
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserCartPage(sessionId: widget.sessionId),
                      ),
                    );
                  },
                  child: const Text("Go to Cart"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
