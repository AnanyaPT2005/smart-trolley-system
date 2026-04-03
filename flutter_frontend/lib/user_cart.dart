// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'barcode.dart';
// import 'config.dart';

// // //8902979022682
// class UserCartPage extends StatefulWidget {
//   final String sessionId;

//   const UserCartPage({required this.sessionId, super.key});

//   @override
//   State<UserCartPage> createState() => _UserCartPageState();
// }

// class _UserCartPageState extends State<UserCartPage> {
//   List items = [];
//   String? trolleyId; // ✅ fetched from backend

//   final String baseUrl = AppConfig.baseUrl;

//   @override
//   void initState() {
//     super.initState();
//     fetchItems();
//     fetchSessionInfo(); // ✅ new
//   }

//   // 🔥 fetch cart items
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

//   // 🔥 fetch trolleyId using sessionId
//   Future<void> fetchSessionInfo() async {
//     try {
//       final response = await http.get(
//         Uri.parse("$baseUrl/session-info/${widget.sessionId}"),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         setState(() {
//           trolleyId = data["trolley_id"];
//         });
//       } else {
//         print("Failed to fetch session info");
//       }
//     } catch (e) {
//       print("Error fetching session info: $e");
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
//               "Trolley: ${trolleyId ?? 'Loading...'}",
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
//                   // 🔥 Header
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

//                   // 🔥 Items
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

//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: SizedBox(
//           height: 60,
//           child: ElevatedButton(
//             onPressed: () {
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       BarcodePage(sessionId: widget.sessionId),
//                 ),
//                 (route) => false, // 🔥 clears entire stack
//               );
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
  String? trolleyId;

  final String baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchItems();
    fetchSessionInfo();
  }

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

  // 🔥 NEW: update quantity
  Future<void> updateQuantity(String barcode, String action) async {
    await http.post(
      Uri.parse("$baseUrl/update-quantity"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "barcode": barcode,
        "action": action,
        "session_id": widget.sessionId,
      }),
    );

    fetchItems(); // refresh
  }

  // 🔥 NEW: delete item
  Future<void> deleteItem(String barcode) async {
    await http.post(
      Uri.parse("$baseUrl/delete-item"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"barcode": barcode, "session_id": widget.sessionId}),
    );

    fetchItems(); // refresh
  }

  double getTotalPrice() {
    double total = 0;

    for (var item in items) {
      final price = (item["price"] as num).toDouble();
      final qty = (item["quantity"] as num).toInt();

      total += price * qty;
    }

    return total;
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
                  // 🔥 Header (UPDATED)
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
                      Text(
                        "Del",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(),

                  // 🔥 Items (UPDATED)
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final barcode = item["barcode"] ?? item["id"];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // name
                              Text(item["name"]),

                              // 🔥 qty controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () =>
                                        updateQuantity(barcode, "decrease"),
                                  ),
                                  Text(item["quantity"].toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () =>
                                        updateQuantity(barcode, "increase"),
                                  ),
                                ],
                              ),

                              // price
                              Text("₹${item["price"]}"),

                              // 🔥 delete button
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteItem(barcode),
                              ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 TOTAL PRICE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "₹${getTotalPrice().toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🔁 Add item button (unchanged)
            SizedBox(
              height: 60,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BarcodePage(sessionId: widget.sessionId),
                    ),
                    (route) => false,
                  );
                },
                child: const Text("Add Item", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
