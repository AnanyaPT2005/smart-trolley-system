// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'barcode.dart';
// import 'config.dart';

// //8902979022682

// class UserCartPage extends StatefulWidget {
//   final String sessionId;

//   const UserCartPage({required this.sessionId, super.key});

//   @override
//   State<UserCartPage> createState() => _UserCartPageState();
// }

// class _UserCartPageState extends State<UserCartPage> {
//   List items = [];

//   final String baseUrl = AppConfig.baseUrl; // same as before

//   @override
//   void initState() {
//     super.initState();
//     fetchItems();
//   }

//   Future<void> fetchItems() async {
//     final response = await http.get(
//       Uri.parse("$baseUrl/get-items/${widget.sessionId}"),
//     );

//     if (response.statusCode == 200) {
//       setState(() {
//         items = json.decode(response.body);
//       });
//     } else {
//       print("Failed to fetch items");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("My Cart"),
//             Text(
//               "Trolley: ${widget.trolleyId}",
//               style: const TextStyle(fontSize: 12),
//             ),
//             Text(
//               "Session: ${widget.sessionId}",
//               style: const TextStyle(fontSize: 12),
//             ),
//           ],
//         ),
//       ),

//       body: items.isEmpty
//           ? const Center(child: Text("Cart is empty"))
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // 🔥 Table Header
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: const [
//                       Text(
//                         "Name",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         "Qty",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         "Price",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                   const Divider(),

//                   // 🔥 Items List
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: items.length,
//                       itemBuilder: (context, index) {
//                         final item = items[index];

//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(item["name"]),
//                               Text(item["quantity"].toString()),
//                               Text("₹${item["price"]}"),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//       // 🔁 Back to barcode
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SizedBox(
//           height: 60,
//           child: ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text("Add Item", style: TextStyle(fontSize: 18)),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'barcode.dart';
import 'config.dart';

class UserCartPage extends StatefulWidget {
  final String sessionId;

  const UserCartPage({required this.sessionId, super.key});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  List items = [];
  String? trolleyId; // ✅ fetched from backend

  final String baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchItems();
    fetchSessionInfo(); // ✅ new
  }

  // 🔥 fetch cart items
  Future<void> fetchItems() async {
    final response = await http.get(
      Uri.parse("$baseUrl/get-items/${widget.sessionId}"),
    );

    if (response.statusCode == 200) {
      setState(() {
        items = json.decode(response.body);
      });
    } else {
      print("Failed to fetch items");
    }
  }

  // 🔥 fetch trolleyId using sessionId
  Future<void> fetchSessionInfo() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/session-info/${widget.sessionId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          trolleyId = data["trolley_id"];
        });
      } else {
        print("Failed to fetch session info");
      }
    } catch (e) {
      print("Error fetching session info: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Cart"),
            Text(
              "Trolley: ${trolleyId ?? 'Loading...'}",
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              "Session: ${widget.sessionId}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),

      body: items.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔥 Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Name",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Qty",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Price",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),

                  // 🔥 Items
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item["name"]),
                              Text(item["quantity"].toString()),
                              Text("₹${item["price"]}"),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BarcodePage(sessionId: widget.sessionId),
                ),
              );
            },
            child: const Text("Add Item", style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}
