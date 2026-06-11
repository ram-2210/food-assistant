import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'orders_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class MenuScreen extends StatefulWidget {
  final int userId;
  const MenuScreen({super.key, required this.userId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // ✅ CHECK YOUR IP
  final String serverIP = '192.168.1.11';

  List<dynamic> menuItems = [];
  bool isLoading = true;
  List<Map<String, dynamic>> cart = [];

  // 🌟 Recommendation Variables
  String recommendedFoodName = "";
  Map<String, dynamic>? recommendedItemData;

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _textSpoken = "Tap Mic to Order 🎤";
  bool _voiceReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchMenu();
    });
  }

  @override
  void dispose() {
    if (_voiceReady) {
      _flutterTts.stop();
    }
    super.dispose();
  }

  Future<void> fetchMenu() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final url = Uri.parse(
      'http://$serverIP/food_api/get_menu.php?user_id=${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            menuItems = json.decode(response.body);
            isLoading = false;
          });
          fetchRecommendation();
        }
      }
    } catch (e) {
      debugPrint("Error fetching menu: $e");
    }
  }

  Future<void> fetchRecommendation() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://$serverIP/food_api/get_recommendation.php?user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          String favName = data['food_name'];

          var foundItem = menuItems.firstWhere(
            (item) => item['name'] == favName,
            orElse: () => null,
          );

          if (foundItem != null && mounted) {
            setState(() {
              recommendedFoodName = favName;
              recommendedItemData = foundItem;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Rec Error: $e");
    }
  }

  // ... Voice Functions ...
  Future<void> _initVoiceFeatures() async {
    try {
      _speech = stt.SpeechToText();
      _flutterTts = FlutterTts();
      await _flutterTts.setLanguage("en-IN");
      if (mounted) setState(() => _voiceReady = true);
    } catch (e) {
      debugPrint("Voice Init Error: $e");
    }
  }

  void _listen() async {
    if (!_voiceReady) await _initVoiceFeatures();
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) => debugPrint('Voice Error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.finalResult) {
              _speech.stop();
              if (mounted) setState(() => _textSpoken = val.recognizedWords);
              checkForFood(val.recognizedWords);
            }
          },
        );
      }
    } else {
      if (mounted) setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> speak(String text) async {
    if (_voiceReady) await _flutterTts.speak(text);
  }

  int extractQuantity(String text) {
    if (text.contains("two") || text.contains("2")) return 2;
    if (text.contains("three") || text.contains("3")) return 3;
    return 1;
  }

  void addToCart(
    int foodId,
    String foodName,
    int quantity,
    String imageUrl,
    int price,
  ) {
    if (mounted) {
      setState(() {
        cart.add({
          "food_id": foodId,
          "food_name": foodName,
          "quantity": quantity,
          "image_url": imageUrl,
          "price": price,
        });
      });
    }
    speak("Added $quantity $foodName");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added $foodName"), backgroundColor: Colors.green),
    );
  }

  void checkForFood(String text) {
    for (var item in menuItems) {
      if (text.toLowerCase().contains(item['name'].toString().toLowerCase())) {
        int price = double.parse(item['price'].toString()).toInt();

        addToCart(
          int.parse(item['id']),
          item['name'],
          1,
          item['image_url'],
          price,
        );
        return;
      }
    }
    speak("Item not found");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Menu"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ProfileScreen(userId: widget.userId),
                ),
              );
              fetchMenu();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => OrdersScreen(userId: widget.userId),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: GestureDetector(
              onTap: () async {
                bool? res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) =>
                        CartScreen(cart: cart, userId: widget.userId),
                  ),
                );
                if (res == true && mounted) setState(() => cart.clear());
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  cart.length.toString(),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            color: Colors.orange[50],
            child: Text(
              _textSpoken,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (recommendedItemData != null)
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your Favorite! 🏆",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        // ✅ FIX: Removed unnecessary braces here
                        Text(
                          "You order $recommendedFoodName a lot.",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Text(
                          "Want it now?",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () {
                      int price = double.parse(
                        recommendedItemData!['price'].toString(),
                      ).toInt();

                      addToCart(
                        int.parse(recommendedItemData!['id']),
                        recommendedItemData!['name'],
                        1,
                        recommendedItemData!['image_url'],
                        price,
                      );
                    },
                    child: const Text(
                      "Add +1",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (ctx, index) {
                      var item = menuItems[index];
                      int price = double.parse(
                        item['price'].toString(),
                      ).toInt();

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.fastfood,
                            color: Colors.orange,
                          ),
                          title: Text(
                            item['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("₹$price"),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              backgroundColor: Colors.orange,
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                            onPressed: () => addToCart(
                              int.parse(item['id']),
                              item['name'],
                              1,
                              item['image_url'],
                              price,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
