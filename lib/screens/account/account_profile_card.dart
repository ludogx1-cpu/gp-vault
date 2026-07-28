import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../src/theme_provider.dart';
import '../../src/firebase_service.dart';
import '../../api_constants.dart';
import '../../widgets/widgets.dart';

class AccountProfileCard extends StatefulWidget {
  final bool isDark;
  final String currentUsername;

  const AccountProfileCard({
    super.key,
    required this.isDark,
    required this.currentUsername,
  });

  @override
  State<AccountProfileCard> createState() => _AccountProfileCardState();
}

class _AccountProfileCardState extends State<AccountProfileCard> {
  final TextEditingController _usernameController = TextEditingController();
  String _usernameMessage = "";
  bool _isSettingUsername = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentUsername != "Anonymous") {
      _usernameController.text = widget.currentUsername;
    }
  }

  Future<void> _processSetUsername() async {
    final name = _usernameController.text.trim();
    if (name.length < 3 || name.length > 15) {
      setState(() => _usernameMessage = "Username must be 3-15 chars.");
      return;
    }

    setState(() {
      _isSettingUsername = true;
      _usernameMessage = "Saving...";
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/set-username'),
        headers: await getAuthHeaders(),
        body: jsonEncode({"username": name}),
      );

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => _usernameMessage = "Username saved successfully!");
      } else {
        setState(() => _usernameMessage = resData['error'] ?? "Failed to save username.");
      }
    } catch (e) {
      setState(() => _usernameMessage = "Connection error.");
    } finally {
      setState(() => _isSettingUsername = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedHoverCard(
      backgroundColor: widget.isDark ? themeProvider.darkGreyBoxColor : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.amber,
        width: 0.5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: gpBrownText(context), size: 30),
                const SizedBox(width: 15),
                Text(
                  "Profile Username",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: gpBrownText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "Set a global username for the Leaderboard and Community Chat. You can only change this once every 3 months.",
              style: TextStyle(
                color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              maxLength: 15,
              style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                counterText: "",
                labelText: "Username",
                hintText: widget.currentUsername == "Anonymous" ? "Enter a username" : widget.currentUsername,
                labelStyle: TextStyle(color: Colors.amber.shade700),
                prefixIcon: const Icon(Icons.badge, color: Colors.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.amber, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (_usernameMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Text(
                  _usernameMessage,
                  style: TextStyle(
                    color: _usernameMessage.contains("success")
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isSettingUsername ? null : _processSetUsername,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              icon: _isSettingUsername
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _isSettingUsername ? "Saving..." : "Update Username",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
