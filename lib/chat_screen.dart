import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

import 'orders_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String serverIP = '192.168.1.11';

  List<Map<String, dynamic>> messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> menuItems = [];
  List<dynamic> suggestionQueue = [];
  int suggestionIndex = 0;
  List<Map<String, dynamic>> cart = [];

  String userName = "Loading...";
  String userDiet = "Veg";

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _voiceReady = false;

  final Color primaryColor = const Color(0xFF00B4D8);
  final Color darkColor = const Color(0xFF03045E);
  final Color bgColor = const Color(0xFFF4F7FC);

  @override
  void initState() {
    super.initState();
    _initVoiceFeatures();
    _initChat();
  }

  Future<void> _initChat() async {
    _addBotMessage("Waking up the kitchen... 🍳");
    await Future.wait([_fetchProfile(), _fetchMenu()]);

    if (mounted) {
      setState(() {
        if (messages.isNotEmpty) messages.clear();
      });
      _sendPersonalizedWelcome();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://$serverIP/food_api/get_profile.php?user_id=${widget.userId}',
        ),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            userName = data['data']['username']?.toString() ?? "User";
            userDiet = data['data']['diet']?.toString().trim() ?? "Veg";
          });
        }
      }
    } catch (e) {
      debugPrint("Profile Error: $e");
    }
  }

  Future<void> _fetchMenu() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://$serverIP/food_api/get_menu.php?user_id=${widget.userId}',
        ),
      );
      if (response.statusCode == 200) {
        setState(() => menuItems = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Menu Error: $e");
    }
  }

  void _sendPersonalizedWelcome() {
    DateTime now = DateTime.now();
    String day = DateFormat('EEEE').format(now);
    String meal = "dinner";
    if (now.hour < 11)
      meal = "breakfast";
    else if (now.hour < 16)
      meal = "lunch";

    String displayMsg =
        "Welcome to Thangam AI! ✨\n\nIt's a beautiful $day, $userName.\nYour profile is set to $userDiet.\n\nWhat delicious meal can I help you find for $meal?";
    _addBotMessage(displayMsg);
  }

  Future<void> _stopVoice() async {
    if (_voiceReady) await _flutterTts.stop();
  }

  void _handleMessage(String text) async {
    if (text.trim().isEmpty) return;

    await _stopVoice();
    _addUserMessage(text);
    _msgController.clear();

    String lowerText = text.toLowerCase();

    // 🌟 FIX: SMARTER CHECKOUT DETECTION 🌟
    // Now it looks for the combination of words, so "complete the order" works!
    bool isCheckoutCommand =
        (lowerText.contains("complete") && lowerText.contains("order")) ||
        (lowerText.contains("freeze") && lowerText.contains("order")) ||
        (lowerText.contains("place") && lowerText.contains("order")) ||
        lowerText.contains("checkout");

    if (isCheckoutCommand) {
      if (cart.isEmpty) {
        _addBotMessage(
          "Your cart is empty! Please add some food before completing your order.",
        );
        _speak("Your cart is empty. Please add some food first.");
      } else {
        int total = cart.fold(
          0,
          (sum, item) =>
              sum + ((item['price'] as int) * (item['quantity'] as int)),
        );

        // 🌟 DATABASE SYNC 🌟
        try {
          await http.post(
            Uri.parse('http://$serverIP/food_api/place_order.php'),
            body: {
              "user_id": widget.userId.toString(),
              "cart_data": json.encode(cart),
              "total_amount": total.toString(),
            },
          );
        } catch (e) {
          debugPrint("Failed to sync order with database: $e");
        }

        // 🌟 SHOW RECEIPT BUBBLE ON SCREEN 🌟
        _addBotMessage("Your order has been sent to the kitchen! 👨‍🍳");
        _addReceiptBubble(cart, total); // Draws the UI Receipt

        _speak(
          "Order completed successfully! The kitchen is preparing your food right now.",
        );

        setState(() {
          cart.clear(); // Empty the cart after successful order
        });
      }
      return;
    }
    // Other local commands
    else if (lowerText.contains("cart")) {
      _addBotMessage(
        "Tap the Cart icon in the bottom menu to view your items.",
      );
      _speak("Please tap the cart icon at the bottom of the screen.");
      return;
    } else if (lowerText.contains("more") || lowerText.contains("else")) {
      _showMoreSuggestions();
      return;
    } else if (lowerText.contains("total") ||
        lowerText.contains("price") ||
        lowerText.contains("bill")) {
      if (cart.isEmpty) {
        _addBotMessage("Your cart is currently empty.");
        _speak("Your cart is currently empty.");
      } else {
        int totalAmount = cart.fold(
          0,
          (sum, item) =>
              sum + ((item['price'] as int) * (item['quantity'] as int)),
        );
        _addBotMessage(
          "You have ${cart.length} items in your cart.\nTotal Price: Rs. $totalAmount\n\nSay 'Complete Order' to finalize!",
        );
        _speak(
          "Your total is $totalAmount rupees. Say complete order when you are ready.",
        );
      }
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$serverIP/food_api/process_order.php'),
        body: {
          "user_id": widget.userId.toString(),
          "text": text,
          "action": "chat",
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          String aiVoice =
              data['ai_voice_response']?.toString() ??
              "Okay, I processed that!";
          _addBotMessage(aiVoice);

          String spokenReply = aiVoice;
          if (spokenReply.contains('\n'))
            spokenReply = spokenReply.split('\n')[0];
          if (spokenReply.contains('**'))
            spokenReply = spokenReply.split('**')[0];
          _speak(spokenReply.trim());

          bool itemsAutoAdded = false;
          if (data['auto_add_items'] != null &&
              data['auto_add_items'].isNotEmpty) {
            for (var item in data['auto_add_items']) {
              _checkRulesAndAdd(item, quiet: false);
            }
            itemsAutoAdded = true;
          }

          if (!itemsAutoAdded &&
              data['carousel_data'] != null &&
              data['carousel_data'].isNotEmpty) {
            setState(() {
              suggestionQueue = data['carousel_data'];
              suggestionIndex = 0;
            });
            _showNextBatch();
          }
        } else {
          _addBotMessage("Error: ${data['message']}");
        }
      } else {
        _addBotMessage(
          "Connection error with the kitchen. (Code: ${response.statusCode})",
        );
      }
    } catch (e) {
      debugPrint("API Error: $e");
      _addBotMessage("I couldn't reach the server. Is XAMPP running?");
    }
  }

  void _showMoreSuggestions() {
    if (suggestionQueue.isEmpty) {
      _addBotMessage("Please ask for food first!");
      return;
    }
    _showNextBatch();
  }

  void _showNextBatch() {
    int count = 0;
    List<dynamic> batch = [];
    while (count < 3 && suggestionIndex < suggestionQueue.length) {
      batch.add(suggestionQueue[suggestionIndex]);
      suggestionIndex++;
      count++;
    }
    if (batch.isNotEmpty) {
      _addCarousel(batch);
      if (suggestionIndex < suggestionQueue.length) {
        Future.delayed(
          const Duration(seconds: 1),
          () => _addBotMessage("Say 'More' to see other options."),
        );
      }
    } else {
      _addBotMessage("That's all I have right now! 🍽️");
    }
  }

  Future<void> _checkRulesAndAdd(dynamic item, {bool quiet = false}) async {
    String type = (item['type'] ?? 'Veg').toString().trim();
    String safeImageUrl =
        item['image_url']?.toString().replaceAll('\\', '/') ?? '';

    if (!safeImageUrl.startsWith('assets/')) {
      safeImageUrl = 'assets/$safeImageUrl';
    }

    if (userDiet == 'Veg' && type == 'Non-Veg') {
      _addBotMessage(
        "🚫 You are Vegetarian! I cannot serve you ${item['name']}.",
      );
      if (!quiet) _speak("Sorry, pure veg only.");
      return;
    }

    int price =
        int.tryParse(item['price'].toString()) ??
        double.tryParse(item['price'].toString())?.toInt() ??
        0;
    int id = int.tryParse(item['id'].toString()) ?? 0;

    _addToCart(id, item['name']?.toString() ?? 'Food', 1, safeImageUrl, price);

    if (!quiet) {
      _addBotMessage(
        "😋 Added ${item['name']} to your cart.",
        imageUrl: safeImageUrl,
      );
    }
  }

  void _addToCart(int id, String name, int qty, String img, int price) {
    setState(() {
      cart.add({
        "food_id": id,
        "food_name": name,
        "quantity": qty,
        "image_url": img,
        "price": price,
      });
    });
  }

  void _addBotMessage(String text, {String? imageUrl}) {
    setState(
      () => messages.add({
        "text": text,
        "isUser": false,
        "image": imageUrl,
        "type": "text",
      }),
    );
    _scrollToBottom();
  }

  void _addCarousel(List<dynamic> foods) {
    setState(
      () => messages.add({"type": "carousel", "isUser": false, "foods": foods}),
    );
    _scrollToBottom();
  }

  // 🌟 DRAWS THE RECEIPT BUBBLE ON SCREEN 🌟
  void _addReceiptBubble(List<Map<String, dynamic>> orderItems, int total) {
    setState(() {
      messages.add({
        "type": "receipt",
        "isUser": false,
        "items": List.from(orderItems), // Saves the exact items ordered
        "total": total,
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(
      () => messages.add({"text": text, "isUser": true, "type": "text"}),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initVoiceFeatures() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    if (mounted) setState(() => _voiceReady = true);
  }

  Future<void> _speak(String text) async {
    if (_voiceReady) {
      try {
        String cleanText = text.replaceAll('*', '').replaceAll('-', '').trim();
        if (cleanText.isNotEmpty) await _flutterTts.speak(cleanText);
      } catch (e) {
        debugPrint("Voice Engine Error: $e");
      }
    }
  }

  void _listen() async {
    await _stopVoice();
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'en_IN',
          pauseFor: const Duration(seconds: 6),
          listenFor: const Duration(seconds: 30),
          onResult: (val) {
            setState(() => _msgController.text = val.recognizedWords);
            if (val.finalResult && val.recognizedWords.trim().isNotEmpty) {
              _handleMessage(val.recognizedWords);
              setState(() => _isListening = false);
            }
          },
        );
      } else {
        _addBotMessage("Please allow microphone permissions in Chrome!");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_msgController.text.trim().isNotEmpty)
        _handleMessage(_msgController.text);
    }
  }

  void _onBottomNavTapped(int index) async {
    if (index == 0) return;
    if (index == 1) {
      bool? res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => CartScreen(cart: cart, userId: widget.userId),
        ),
      );
      if (res == true && mounted) setState(() => cart.clear());
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => OrdersScreen(userId: widget.userId)),
      );
    } else if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (c) => ProfileScreen(userId: widget.userId)),
      );
      if (mounted) _initChat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: const AssetImage('assets/bot.png'),
              child: const Icon(Icons.smart_toy, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Thangam AI",
                  style: TextStyle(
                    color: darkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Online",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemBuilder: (context, index) {
                var msg = messages[index];
                bool isUser = msg['isUser'];

                if (msg['type'] == 'carousel')
                  return _buildCarousel(msg['foods']);

                // 🌟 RENDERS THE DIGITAL RECEIPT BUBBLE 🌟
                if (msg['type'] == 'receipt') {
                  return _buildReceiptCard(msg['items'], msg['total']);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[
                        const CircleAvatar(
                          radius: 14,
                          backgroundImage: AssetImage('assets/bot.png'),
                          backgroundColor: Colors.transparent,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? primaryColor : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isUser
                                  ? const Radius.circular(20)
                                  : const Radius.circular(4),
                              bottomRight: isUser
                                  ? const Radius.circular(4)
                                  : const Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: darkColor.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'],
                                style: TextStyle(
                                  fontSize: 15.5,
                                  height: 1.4,
                                  color: isUser ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (msg['image'] != null) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    msg['image'],
                                    height: 140,
                                    width: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      height: 140,
                                      width: 220,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.fastfood,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 20),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _msgController,
                      onTap: _stopVoice,
                      onChanged: (val) => _stopVoice(),
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: "Type 'Order Biryani'...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: _handleMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _listen,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: _isListening
                        ? Colors.redAccent
                        : primaryColor,
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _handleMessage(_msgController.text),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: darkColor,
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        currentIndex: 0,
        onTap: _onBottomNavTapped,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        elevation: 15,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(cart.length.toString()),
              isLabelVisible: cart.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // 🌟 THE RECEIPT WIDGET DESIGN 🌟
  Widget _buildReceiptCard(List<dynamic> items, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 26),
                const SizedBox(width: 8),
                const Text(
                  "Order Completed!",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1.5),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item['quantity']}x ${item['food_name']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "Rs. ${item['price'] * item['quantity']}",
                      style: TextStyle(
                        color: darkColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24, thickness: 1.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Paid:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Rs. $total",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(List<dynamic> foods) {
    return Container(
      height: 260,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: foods.length,
        itemBuilder: (context, i) {
          var food = foods[i];
          String safeImageUrl =
              food['image_url']?.toString().replaceAll('\\', '/') ?? '';
          if (!safeImageUrl.startsWith('assets/'))
            safeImageUrl = 'assets/$safeImageUrl';

          return GestureDetector(
            onTap: () => _checkRulesAndAdd(food),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15, bottom: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: darkColor.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.asset(
                      safeImageUrl,
                      height: 130,
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 130,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food['name']?.toString() ?? 'Food',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: darkColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rs. ${food['price']}",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "+ Add",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
