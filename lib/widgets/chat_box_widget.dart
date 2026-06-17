import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../api_constants.dart';

class ChatBoxWidget extends StatefulWidget {
  const ChatBoxWidget({super.key});

  @override
  State<ChatBoxWidget> createState() => _ChatBoxWidgetState();
}

class _ChatBoxWidgetState extends State<ChatBoxWidget> {
  bool _isExpanded = false;
  bool _hasUnread = false;
  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isOnCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  bool _hasUsername = true; // Assume true until we load
  bool _isCheckingUsername = true;

  @override
  void initState() {
    super.initState();
    _checkUsername();

    FirebaseFirestore.instance
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (!_isExpanded && snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _hasUnread = true;
          });
        }
      }
    });
  }

  Future<void> _checkUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['chat_username'] == null || data['chat_username'].toString().isEmpty) {
          if (mounted) {
            setState(() {
              _hasUsername = false;
            });
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _isCheckingUsername = false;
      });
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _usernameController.dispose();
    _scrollController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeProvider.isDarkMode ? themeProvider.darkGreyBoxColor : Colors.white,
          title: Text(
            "Community Chat Rules",
            style: TextStyle(color: gpBrownText(context), fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ruleItem("1. No links or advertisements of any kind."),
              _ruleItem("2. No begging or asking for funds."),
              _ruleItem("3. Be respectful. No profanity or abuse."),
              const SizedBox(height: 10),
              Text(
                "SWEAR JAR: Swearing will result in a 0.005 DOGE fine.",
                style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 5),
              Text(
                "Violators will be progressively banned from chat.",
                style: TextStyle(color: Colors.orange.shade400, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("I Understand"),
            ),
          ],
        );
      },
    );
  }

  Widget _ruleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
          fontSize: 14,
        ),
      ),
    );
  }

  void _startCooldown() {
    setState(() {
      _isOnCooldown = true;
      _cooldownSeconds = 10;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _isOnCooldown = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _setUsername() async {
    final name = _usernameController.text.trim();
    if (name.length < 3 || name.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username must be 3-15 chars")));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/set-username'),
        headers: await getAuthHeaders(),
        body: jsonEncode({"username": name}),
      );
      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _hasUsername = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username set!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resData['error'] ?? "Failed to set username")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error connecting to server")));
    }
  }

  Future<void> _sendMessage() async {
    if (_isOnCooldown) return;
    
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    if (text.length > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message is too long (max 150 chars).")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to chat.")),
      );
      return;
    }

    setState(() {
      _msgController.clear();
    });
    
    _startCooldown();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/send'),
        headers: await getAuthHeaders(),
        body: jsonEncode({"message": text}),
      );

      final resData = jsonDecode(response.body);
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resData['error'] ?? 'Message failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message.")),
      );
    }
  }

  Future<void> _banUser(String targetUid, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/ban'),
        headers: await getAuthHeaders(),
        body: jsonEncode({"target_uid": targetUid, "reason": reason}),
      );
      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User banned successfully")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resData['error'] ?? "Ban failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to connect")));
    }
  }

  Future<void> _emptyJar() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/chat/payout-jar'),
        headers: await getAuthHeaders(),
      );
      final resData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resData['message'] ?? "Jar emptied!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resData['error'] ?? "Failed to empty jar")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to connect")));
    }
  }

  Widget _buildMinimized() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = true;
          _hasUnread = false;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, color: Colors.brown, size: 30),
            if (_hasUnread)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    final isDark = themeProvider.isDarkMode;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserAdmin = currentUser?.uid == 'P8iffVqbUgetAVA4MdHVZ1CfvUv1';
    
    return Container(
      width: 320,
      height: 450,
      decoration: BoxDecoration(
        color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? themeProvider.darkGreyBorder : Colors.amber.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat, color: Colors.brown, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Community Chat",
                      style: TextStyle(
                        color: gpBrownText(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.gavel, size: 20, color: Colors.brown),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _showRulesDialog,
                      tooltip: "Chat Rules",
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.brown),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Swear Jar Pot Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Swear Jar Pot",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('system').doc('swear_jar').snapshots(),
                        builder: (context, snapshot) {
                          double balance = 0.0;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            balance = (snapshot.data!.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;
                          }
                          return Text(
                            "${balance.toStringAsFixed(5)} DOGE",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (isCurrentUserAdmin)
                  ElevatedButton(
                    onPressed: _emptyJar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text("Empty Jar", style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // Messages Area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_messages')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || _isCheckingUsername) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!_hasUsername) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 40, color: isDark ? Colors.white54 : Colors.black54),
                          const SizedBox(height: 10),
                          Text(
                            "Choose a Username",
                            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "You can only change this once every 3 months.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _usernameController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: "Username",
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _setUsername,
                            child: const Text("Set Username"),
                          )
                        ],
                      ),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet.\nSay hi!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isAdmin = data['is_admin'] == true;
                    String senderUid = data['uid'] ?? '';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                data['display_name'] ?? 'User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isAdmin ? Colors.amber.shade700 : (isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                                ),
                              ),
                              if (isAdmin)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4.0),
                                  child: Icon(Icons.verified, size: 12, color: Colors.amber),
                                ),
                              const Spacer(),
                              if (isCurrentUserAdmin && !isAdmin)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 14, color: Colors.grey),
                                  padding: EdgeInsets.zero,
                                  tooltip: "Admin Tools",
                                  onSelected: (val) {
                                    _banUser(senderUid, val);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'general',
                                      child: Text("Ban (General)"),
                                    ),
                                    const PopupMenuItem(
                                      value: 'link',
                                      child: Text("Ban (Link)"),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data['message'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input Area
          if (_hasUsername)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      maxLength: 150,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isOnCooldown
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "$_cooldownSeconds",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.amber),
                          onPressed: _sendMessage,
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isExpanded ? _buildExpanded() : _buildMinimized(),
      ),
    );
  }
}
