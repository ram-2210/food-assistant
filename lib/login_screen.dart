import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart'; // ✅ CHANGED: Import Chat Screen
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ CHECK YOUR IP
  final String serverIP = '192.168.1.11';

  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    // 1. Close Keyboard & Wait
    FocusScope.of(context).unfocus();

    if (userController.text.isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      debugPrint("Logging in to: http://$serverIP/food_api/login.php");

      final response = await http.post(
        Uri.parse('http://$serverIP/food_api/login.php'),
        body: {
          "username": userController.text,
          "password": passController.text,
        },
      );

      // ✅ FIX: Check if screen is still active
      if (!mounted) return;

      debugPrint("Server Response: ${response.body}");

      if (response.body.trim().startsWith("<")) {
        throw FormatException("Server Error (HTML Response): ${response.body}");
      }

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        int userId = int.parse(data['user_id'].toString());

        // 2. Wait for keyboard to fully go away
        await Future.delayed(const Duration(milliseconds: 500));

        // ✅ FIX: Check mounted again after delay
        if (!mounted) return;

        // 🛡️ NAVIGATION TO CHAT SCREEN
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            // ✅ CHANGED: Open ChatScreen instead of MenuScreen
            pageBuilder: (context, animation1, animation2) =>
                ChatScreen(userId: userId),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fastfood, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                "Welcome Back!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 25),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: login,
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text("New here? Create an Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
