import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/firebase_service.dart';
import '../api_constants.dart';

class ProfileSetupDialog extends StatefulWidget {
  final String currentUsername;
  final String currentPetName;

  const ProfileSetupDialog({
    super.key,
    required this.currentUsername,
    required this.currentPetName,
  });

  @override
  State<ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends State<ProfileSetupDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _petNameController;
  bool _isLoading = false;
  String _message = "";

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.currentUsername.isEmpty || widget.currentUsername == 'Anonymous' ? '' : widget.currentUsername,
    );
    _petNameController = TextEditingController(
      text: widget.currentPetName == 'Golden Paw Shiba' ? '' : widget.currentPetName,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final petName = _petNameController.text.trim();

    if (username.isEmpty || petName.isEmpty) {
      setState(() => _message = "Please fill in both fields.");
      return;
    }

    if (username.length < 3 || username.length > 15) {
      setState(() => _message = "Username must be 3-15 chars.");
      return;
    }
    
    if (petName.length > 20) {
      setState(() => _message = "Pet name is too long.");
      return;
    }

    setState(() {
      _isLoading = true;
      _message = "Saving...";
    });

    try {
      final headers = await getAuthHeaders();
      
      // Save Username
      final userRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/set-username'),
        headers: headers,
        body: jsonEncode({"username": username}),
      );
      
      // Save Pet Name
      final petRes = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-rename'),
        headers: headers,
        body: jsonEncode({'newName': petName}),
      );

      if (userRes.statusCode == 200 && petRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        final petData = jsonDecode(petRes.body);
        
        if (userData['success'] == true && petData['success'] == true) {
          // Mark setup as complete in the user's Firestore document
          try {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .set({'setupComplete': true}, SetOptions(merge: true));
            }
          } catch (_) {}
          if (mounted) {
            Navigator.pop(context, true);
          }
          return;
        } else {
           setState(() => _message = userData['error'] ?? petData['error'] ?? "Failed to save. Try again.");
        }
      } else {
         String errorMsg = "Server error. Try again.";
         try {
           if (userRes.statusCode != 200) {
             final d = jsonDecode(userRes.body);
             if (d['error'] != null) errorMsg = d['error'];
           } else if (petRes.statusCode != 200) {
             final d = jsonDecode(petRes.body);
             if (d['error'] != null) errorMsg = d['error'];
           }
         } catch(e) {}
         setState(() => _message = errorMsg);
      }
    } catch (e) {
      setState(() => _message = "Connection error.");
    } finally {
      if (mounted) {
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Welcome to Golden Paw! \ud83d\udc3e"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Before you start exploring, let's set up your profile and name your new virtual Shiba Inu!"),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Your Username",
                hintText: "e.g. DogeMaster99",
                border: OutlineInputBorder(),
              ),
              maxLength: 15,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _petNameController,
              decoration: const InputDecoration(
                labelText: "Your Shiba's Name",
                hintText: "e.g. Sparky",
                border: OutlineInputBorder(),
              ),
              maxLength: 20,
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains("error") || _message.contains("Failed") || _message.contains("fill") || _message.contains("must") || _message.contains("long") 
                    ? Colors.red 
                    : Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text("I'll do this later"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("Save & Continue"),
        ),
      ],
    );
  }
}
