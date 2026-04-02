// import 'package:flutter/material.dart';
// import 'barcode.dart';

// class UserCartPage extends StatelessWidget {
//   final String sessionId; // ✅ store sessionId

//   const UserCartPage({required this.sessionId, super.key}); // ✅ constructor

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("My Cart")),

//       body: Center(
//         child: Text(
//           "My Cart\nSession: $sessionId", // optional debug
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
//               // ✅ go back OR pass again
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => BarcodePage(sessionId: sessionId),
//                 ),
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
//8902979022682

class UserCartPage extends StatefulWidget {
  final String sessionId;

  const UserCartPage({required this.sessionId, super.key});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  List items = [];

  final String baseUrl = "http://192.168.1.6:5000"; // same as before

  @override
  void initState() {
    super.initState();
    fetchItems();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),

      body: items.isEmpty
          ? const Center(child: Text("Cart is empty"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🔥 Table Header
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

                  // 🔥 Items List
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

      // 🔁 Back to barcode
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Add Item", style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}
