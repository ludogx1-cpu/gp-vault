import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../api_constants.dart';
import '../src/firebase_service.dart';

class WalkTreadmillDialog extends StatefulWidget {
  const WalkTreadmillDialog({super.key});

  @override
  State<WalkTreadmillDialog> createState() => _WalkTreadmillDialogState();
}

class _WalkTreadmillDialogState extends State<WalkTreadmillDialog> with TickerProviderStateMixin {
  int _distanceMeters = 0;
  bool _isWalking = false;
  bool _isSaving = false;
  double _dogeEarned = 0;
  
  late AnimationController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _tapToWalk() {
    if (_isSaving) return;
    
    setState(() {
      _distanceMeters += 2;
      _isWalking = true;
    });

    _scrollController.forward(from: 0).then((_) {
      if (mounted) setState(() => _isWalking = false);
    });
  }

  Future<void> _endWalk() async {
    if (_distanceMeters == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-walk-sync'),
        headers: headers,
        body: jsonEncode({'distance_meters': _distanceMeters}),
      );
      
      final data = jsonDecode(response.body);
      if (data['success'] && mounted) {
        setState(() {
          _dogeEarned = (data['reward'] as num).toDouble();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Walk complete! Earned ${_dogeEarned.toStringAsFixed(4)} DOGE'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to sync walk'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Treadmill Walk"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Tap the 'Step' button to make your pet walk! It costs Energy but earns DOGE.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 20),
          
          // Mini Treadmill view
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scrolling floor effect
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _scrollController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (i) {
                          return Transform.translate(
                            offset: Offset(-_scrollController.value * 20, 0),
                            child: Container(width: 20, height: 4, color: Colors.grey.shade400),
                          );
                        }),
                      );
                    },
                  ),
                ),
                
                // Pet
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  transform: Matrix4.translationValues(0, _isWalking ? -10 : 0, 0),
                  child: Image.asset('assets/shiba_adult.png', height: 80),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Text("Distance: $_distanceMeters m", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _tapToWalk,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("STEP!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _endWalk,
          child: const Text("Finish Walk"),
        ),
      ],
    );
  }
}
