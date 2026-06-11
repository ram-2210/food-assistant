import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; // To access LoginScreen

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ✅ CHECK YOUR IP
  final String serverIP = '192.168.1.11';

  // User Data
  String name = "Loading...";
  String globalDiet = "Veg";
  String address = "";

  // 🌟 WEEKLY MEAL PLAN WITH DAILY DIET TOGGLE 🌟
  Map<String, Map<String, String>> mealPlan = {
    'Monday': {'Breakfast': '', 'Lunch': '', 'Dinner': '', 'Diet': 'Veg'},
    'Tuesday': {'Breakfast': '', 'Lunch': '', 'Dinner': '', 'Diet': 'Veg'},
    'Wednesday': {'Breakfast': '', 'Lunch': '', 'Dinner': '', 'Diet': 'Veg'},
    'Thursday': {'Breakfast': '', 'Lunch': '', 'Dinner': '', 'Diet': 'Veg'},
    'Friday': {'Breakfast': '', 'Lunch': '', 'Dinner': '', 'Diet': 'Veg'},
    'Saturday': {'Breakfast': '', 'Lunch': '', 'Dinner': '', 'Diet': 'Veg'},
    'Sunday': {'Breakfast': '', 'Lunch': '', 'Dinner': '', 'Diet': 'Veg'},
  };

  bool _isLoading = true;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // --- 1. DATA FETCHING LOGIC ---
  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://$serverIP/food_api/get_profile.php?user_id=${widget.userId}',
        ),
      );

      if (response.statusCode == 200) {
        if (response.body.trim().startsWith("<")) {
          debugPrint("Server Error: ${response.body}");
          return;
        }

        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              name = data['data']['username'] ?? "User";
              globalDiet = data['data']['diet'] ?? "Veg";
              address = data['data']['address'] ?? "No address set";

              // Set default daily diet to whatever their global profile is
              for (var day in _days) {
                mealPlan[day]!['Diet'] = globalDiet;
              }

              // Extract the saved Meal Plan JSON
              if (data['data']['restrictions'] != null) {
                var rawRest = data['data']['restrictions'];
                if (rawRest is String && rawRest.isNotEmpty) {
                  try {
                    var decoded = json.decode(rawRest);
                    if (decoded is Map) {
                      for (var day in _days) {
                        if (decoded.containsKey(day) && decoded[day] is Map) {
                          mealPlan[day]!['Breakfast'] =
                              decoded[day]['Breakfast']?.toString() ?? '';
                          mealPlan[day]!['Lunch'] =
                              decoded[day]['Lunch']?.toString() ?? '';
                          mealPlan[day]!['Dinner'] =
                              decoded[day]['Dinner']?.toString() ?? '';
                          mealPlan[day]!['Diet'] =
                              decoded[day]['Diet']?.toString() ?? globalDiet;
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint("JSON Parse Error: $e");
                  }
                }
              }
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. EDIT DIALOGS ---

  void _showGeneralEditDialog() {
    TextEditingController addrController = TextEditingController(text: address);
    String tempDiet = globalDiet;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 10,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Center(
                      child: Text(
                        "Update your preferences below",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      "Global Diet Plan",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.purple.shade100),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tempDiet,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down_circle,
                            color: Colors.purple,
                          ),
                          items: ['Veg', 'Non-Veg'].map((String val) {
                            return DropdownMenuItem(
                              value: val,
                              child: Row(
                                children: [
                                  Icon(
                                    val == 'Veg'
                                        ? Icons.spa
                                        : Icons.kebab_dining,
                                    color: val == 'Veg'
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    val,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => tempDiet = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Delivery Address",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addrController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Enter your address...",
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.purple.shade100),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.purple.shade100),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Colors.purple,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _saveFullProfile(
                                tempDiet,
                                addrController.text,
                                json.encode(mealPlan),
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: Colors.purple.withValues(alpha: 0.4),
                            ),
                            child: const Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showScheduleEditor() {
    Map<String, Map<String, TextEditingController>> tempControllers = {};
    Map<String, String> tempDailyDiet = {};

    for (var day in _days) {
      tempDailyDiet[day] = mealPlan[day]!['Diet'] ?? globalDiet;
      tempControllers[day] = {
        'Breakfast': TextEditingController(text: mealPlan[day]!['Breakfast']),
        'Lunch': TextEditingController(text: mealPlan[day]!['Lunch']),
        'Dinner': TextEditingController(text: mealPlan[day]!['Dinner']),
      };
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // Added StatefulBuilder for the toggle buttons
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Weekly Meal Planner",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    String day = _days[index];
                    bool isDayVeg = tempDailyDiet[day] == 'Veg';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: Colors.purple,
                          ),

                          // 🌟 NEW: Daily Diet Toggle Button 🌟
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    tempDailyDiet[day] = isDayVeg
                                        ? 'Non-Veg'
                                        : 'Veg';
                                  });
                                },
                                child: _buildStatusTag(
                                  isDayVeg ? "Veg" : "Non-Veg",
                                  isDayVeg ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          children: [
                            _buildMealInput(
                              "🌅 Breakfast",
                              tempControllers[day]!['Breakfast']!,
                            ),
                            const SizedBox(height: 10),
                            _buildMealInput(
                              "☀️ Lunch",
                              tempControllers[day]!['Lunch']!,
                            ),
                            const SizedBox(height: 10),
                            _buildMealInput(
                              "🌙 Dinner",
                              tempControllers[day]!['Dinner']!,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Map<String, Map<String, String>> newPlan = {};
                    for (var day in _days) {
                      newPlan[day] = {
                        'Breakfast': tempControllers[day]!['Breakfast']!.text
                            .trim(),
                        'Lunch': tempControllers[day]!['Lunch']!.text.trim(),
                        'Dinner': tempControllers[day]!['Dinner']!.text.trim(),
                        'Diet': tempDailyDiet[day]!,
                      };
                    }

                    await _saveFullProfile(
                      globalDiet,
                      address,
                      json.encode(newPlan),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Save Plan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMealInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: "e.g. Idli & Tea",
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _saveFullProfile(String d, String a, String r) async {
    setState(() {
      globalDiet = d;
      address = a;
      try {
        var decoded = json.decode(r);
        for (var day in _days) {
          if (decoded.containsKey(day)) {
            mealPlan[day]!['Breakfast'] = decoded[day]['Breakfast'] ?? '';
            mealPlan[day]!['Lunch'] = decoded[day]['Lunch'] ?? '';
            mealPlan[day]!['Dinner'] = decoded[day]['Dinner'] ?? '';
            mealPlan[day]!['Diet'] = decoded[day]['Diet'] ?? globalDiet;
          }
        }
      } catch (e) {
        debugPrint("Sync Error");
      }
    });

    try {
      final response = await http.post(
        Uri.parse('http://$serverIP/food_api/update_profile.php'),
        body: {
          'user_id': widget.userId.toString(),
          'diet': d,
          'address': a,
          'restrictions': r,
        },
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("✅ Profile Saved!")));
        }
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- 3. PROFESSIONAL UI BUILD ---
  @override
  Widget build(BuildContext context) {
    bool isVeg = globalDiet == 'Veg';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: _showGeneralEditDialog,
              tooltip: "Edit Info",
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Stack(
              children: [
                Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 110),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const CircleAvatar(
                                radius: 55,
                                backgroundColor: Color(0xFFF3E5F5),
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isVeg ? Icons.eco : Icons.lunch_dining,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isVeg
                                        ? "Pure Vegetarian"
                                        : "Non-Veg Profile",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.location_on,
                              "Delivery Address",
                              address.isEmpty ? "Not set" : address,
                              Colors.blueAccent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Weekly Plan",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showScheduleEditor,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.purple.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            label: const Text(
                              "Edit",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _days.length,
                        itemBuilder: (context, index) {
                          String day = _days[index];

                          bool hasPlan =
                              mealPlan[day]!['Breakfast']!.isNotEmpty ||
                              mealPlan[day]!['Lunch']!.isNotEmpty ||
                              mealPlan[day]!['Dinner']!.isNotEmpty;

                          bool isDayVeg = mealPlan[day]!['Diet'] == 'Veg';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.purple,
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    _buildStatusTag(
                                      isDayVeg ? "Veg Day" : "Non-Veg Day",
                                      isDayVeg ? Colors.green : Colors.red,
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  hasPlan
                                      ? "Meals planned"
                                      : "No meals planned",
                                  style: TextStyle(
                                    color: hasPlan ? Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                children: [
                                  if (mealPlan[day]!['Breakfast']!.isNotEmpty)
                                    _buildMealDisplayRow(
                                      "Breakfast",
                                      Icons.free_breakfast,
                                      mealPlan[day]!['Breakfast']!,
                                      Colors.orange,
                                    ),
                                  if (mealPlan[day]!['Lunch']!.isNotEmpty)
                                    _buildMealDisplayRow(
                                      "Lunch",
                                      Icons.wb_sunny,
                                      mealPlan[day]!['Lunch']!,
                                      Colors.blue,
                                    ),
                                  if (mealPlan[day]!['Dinner']!.isNotEmpty)
                                    _buildMealDisplayRow(
                                      "Dinner",
                                      Icons.nights_stay,
                                      mealPlan[day]!['Dinner']!,
                                      Colors.indigo,
                                    ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 10),
                              Text(
                                "Log Out",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealDisplayRow(
    String mealTime,
    IconData icon,
    String food,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  food,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
