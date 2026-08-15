import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isAdmin;
  final bool isCurrentUserAdmin;
  final bool isDark;
  final String senderUid;
  final Function(String, String) onBan;

  const ChatMessageBubble({
    super.key,
    required this.data,
    required this.isAdmin,
    required this.isCurrentUserAdmin,
    required this.isDark,
    required this.senderUid,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data['display_name'] ?? data['chat_username'] ?? 'User',
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
                  onSelected: (val) => onBan(senderUid, val),
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
  }
}
