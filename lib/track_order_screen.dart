import 'package:flutter/material.dart';

class TrackOrderScreen extends StatelessWidget {
  final String status;
  final int orderId;
  final double totalAmount;

  const TrackOrderScreen({
    super.key,
    required this.status,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Logic to determine which step is active
    int currentStep = 1;
    String lowerStatus = status.toLowerCase();

    // ✅ FIX 1: Added curly braces {}
    if (lowerStatus == 'pending') {
      currentStep = 1;
    } else if (lowerStatus == 'cooking') {
      currentStep = 2;
    } else if (lowerStatus == 'out for delivery') {
      currentStep = 3;
    } else if (lowerStatus == 'delivered') {
      currentStep = 4;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Track Order #$orderId"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Time Estimate Card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                // ✅ FIX 2: Added const
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Estimated Time:", style: TextStyle(color: Colors.grey)),
                  Text(
                    "30-40 Mins",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Timeline Visuals
            _buildStep(
              "Order Placed",
              "We have received your order",
              1,
              currentStep,
            ),
            _buildLine(1, currentStep),
            _buildStep(
              "Cooking",
              "Chef is preparing your food",
              2,
              currentStep,
            ),
            _buildLine(2, currentStep),
            _buildStep(
              "Out for Delivery",
              "Rider is on the way",
              3,
              currentStep,
            ),
            _buildLine(3, currentStep),
            _buildStep("Delivered", "Enjoy your meal!", 4, currentStep),

            const Spacer(),

            // Total
            Text(
              "Total: ₹$totalAmount",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper for the Dot and Text
  Widget _buildStep(
    String title,
    String subtitle,
    int stepIndex,
    int currentStep,
  ) {
    bool isActive = stepIndex <= currentStep;
    return Row(
      children: [
        Column(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isActive ? Colors.green : Colors.grey,
              size: 30,
            ),
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isActive ? Colors.black : Colors.grey,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // Helper for the Line
  Widget _buildLine(int stepIndex, int currentStep) {
    bool isActive = stepIndex < currentStep;
    return Container(
      margin: const EdgeInsets.only(left: 14),
      height: 40,
      width: 2,
      color: isActive ? Colors.green : Colors.grey[300],
    );
  }
}
