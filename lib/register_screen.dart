import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ✅ UPDATED IP: Ensure this matches your PC's 'ipconfig'
  final String serverIP = '192.168.1.11';

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _addrController =
      TextEditingController(); // ✅ NEW Controller

  // Default diet
  String _diet = 'Veg';
  bool _isLoading = false;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Meat Status (True = Meat Allowed, False = Veg Only)
  final Map<String, bool> _meatAllowed = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': true,
  };

  // Restriction Boxes
  final Map<String, TextEditingController> _dayControllers = {};

  @override
  void initState() {
    super.initState();
    for (var day in _days) {
      _dayControllers[day] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _dayControllers.values) {
      controller.dispose();
    }
    _userController.dispose();
    _passController.dispose();
    _addrController.dispose(); // ✅ Dispose new controller
    super.dispose();
  }

  Future<void> _signup() async {
    // ✅ Check if Address is filled
    if (_userController.text.isEmpty ||
        _passController.text.isEmpty ||
        _addrController.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    Map<String, List<String>> rules = {};

    for (var day in _days) {
      List<String> bans = [];

      // RULE 1: Meat Check (Only for Non-Veg Users)
      if (_diet == 'Non-Veg') {
        if (_meatAllowed[day] == false) {
          bans.add("Non-Veg");
        }
      }

      // RULE 2: Restriction Box (For EVERYONE)
      String text = _dayControllers[day]!.text.toLowerCase().trim();
      if (text.isNotEmpty) {
        text = text.replaceAll("no ", "");
        List<String> ingredients = text.split(',');
        for (var ing in ingredients) {
          bans.add(ing.trim());
        }
      }

      if (bans.isNotEmpty) {
        rules[day] = bans;
      }
    }

    String rulesJson = json.encode(rules);

    try {
      final response = await http.post(
        Uri.parse('http://$serverIP/food_api/signup.php'),
        body: {
          'username': _userController.text,
          'password': _passController.text,
          'diet': _diet,
          'address': _addrController.text, // ✅ Send Address to Server
          'restrictions': rulesJson,
        },
      );

      var data = json.decode(response.body);
      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Account Created! Login now.")),
          );
          Navigator.pop(context);
        }
      } else {
        _showError(data['message']);
      }
    } catch (e) {
      _showError("Connection Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.deepPurpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Username Field
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.purple,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password Field
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock, color: Colors.purple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🏠 NEW ADDRESS FIELD
                  TextField(
                    controller: _addrController,
                    maxLines: 2, // Allow 2 lines for address
                    decoration: InputDecoration(
                      labelText: "Delivery Address",
                      prefixIcon: const Icon(Icons.home, color: Colors.purple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🥗 Diet Selection Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _diet,
                        isExpanded: true,
                        items: ['Veg', 'Non-Veg'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(
                                  value == 'Veg'
                                      ? Icons.grass
                                      : Icons.kebab_dining,
                                  color: value == 'Veg'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  value,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _diet = newValue!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Daily Preferences:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 📅 DYNAMIC DAYS LIST
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _days.length,
                    itemBuilder: (context, index) {
                      String day = _days[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Header Row (Day Name + Toggle Button)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  day,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                // 🔘 TOGGLE BUTTON (Only for Non-Veg Users)
                                if (_diet == 'Non-Veg')
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _meatAllowed[day] = !_meatAllowed[day]!;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        // ✅ FIX: Replaced withOpacity with withValues
                                        color: _meatAllowed[day]!
                                            ? Colors.redAccent.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.green.withValues(
                                                alpha: 0.1,
                                              ),
                                        border: Border.all(
                                          color: _meatAllowed[day]!
                                              ? Colors.red
                                              : Colors.green,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _meatAllowed[day]!
                                                ? Icons.kebab_dining
                                                : Icons.grass,
                                            size: 16,
                                            color: _meatAllowed[day]!
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _meatAllowed[day]!
                                                ? "Meat Allowed"
                                                : "No Meat",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _meatAllowed[day]!
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // 📝 Restriction Box
                            TextField(
                              controller: _dayControllers[day],
                              decoration: InputDecoration(
                                labelText: "Restrictions for $day",
                                hintText: "e.g. No onion",
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                prefixIcon: const Icon(
                                  Icons.block,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // CREATE ACCOUNT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "CREATE ACCOUNT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
