import 'package:flutter/material.dart';

class StakingForm extends StatelessWidget {
  final TextEditingController amountController;
  final bool isProcessing;
  final bool isDark;
  final Function(double) onStake;
  final Function(double) onUnstake;
  final BuildContext context;

  const StakingForm({
    super.key,
    required this.amountController,
    required this.isProcessing,
    required this.isDark,
    required this.onStake,
    required this.onUnstake,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Column(
      children: [
        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: 'Principal Amount to Stake / Unstake',
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : null,
            ),
            prefixIcon: const Icon(
              Icons.monetization_on,
              color: Colors.amber,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: isDark
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.white24,
                    ),
                  )
                : null,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.amber,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () {
                          double amount = double.tryParse(
                                amountController.text.trim(),
                              ) ??
                              0.0;
                          if (amount > 0) {
                            onStake(amount);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a valid amount to stake."),
                              ),
                            );
                          }
                        },
                  icon: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    "STAKE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () {
                          double amount = double.tryParse(
                                amountController.text.trim(),
                              ) ??
                              0.0;
                          if (amount > 0) {
                            onUnstake(amount);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a valid amount to unstake."),
                              ),
                            );
                          }
                        },
                  icon: const Icon(
                    Icons.lock_open,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    "UNSTAKE",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.amber : Colors.amber.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
