import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ✅ CHECK YOUR IP
  final String serverIP = 'flutter attach192.168.1.11';

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  String _diet = 'Veg'; // Default
  bool _isLoading = false;

  // List of days
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // To store which days are selected
  final Map<String, bool> _selectedDays = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  Future<void> _signup() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    // 🧠 LOGIC: If Veg, send empty string. If Non-Veg, send comma-separated days.
    String daysString = "";
    if (_diet == 'Non-Veg') {
      List<String> activeDays = [];
      _selectedDays.forEach((key, value) {
        if (value) activeDays.add(key);
      });
      daysString = activeDays.join(","); // e.g., "Monday,Wednesday"
    }

    try {
      final response = await http.post(
        Uri.parse('http://$serverIP/food_api/signup.php'),
        body: {
          'username': _userController.text,
          'password': _passController.text,
          'diet': _diet,
          'non_veg_days': daysString,
        },
      );

      var data = json.decode(response.body);
      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Account Created! Login now.")),
          );
          Navigator.pop(context); // Go back to Login
        }
      } else {
        _showError(data['message']);
      }
    } catch (e) {
      _showError("Connection Error");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.deepOrangeAccent],
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
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Username
                  TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.orange,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🥗 Diet Selection
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

                  // 📅 Days Selection (HIDDEN if Veg)
                  if (_diet == 'Non-Veg') ...[
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Select Meat Days:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Column(
                      children: _days.map((day) {
                        return CheckboxListTile(
                          title: Text(day),
                          value: _selectedDays[day],
                          activeColor: Colors.orange,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (bool? val) {
                            setState(() {
                              _selectedDays[day] = val!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
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
