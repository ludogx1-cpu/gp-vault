import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';

class NewsletterSubscribeWidget extends StatefulWidget {
  const NewsletterSubscribeWidget({super.key});

  @override
  State<NewsletterSubscribeWidget> createState() => _NewsletterSubscribeWidgetState();
}

class _NewsletterSubscribeWidgetState extends State<NewsletterSubscribeWidget> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  Future<void> _subscribe() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = "Please enter a valid email address.";
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // Add email to Firestore 'subscribers' collection
      await FirebaseFirestore.instance.collection('subscribers').add({
        'email': email,
        'subscribed_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _message = "Thank you for subscribing!";
        _isSuccess = true;
        _emailController.clear();
      });
    } catch (e) {
      setState(() {
        _message = "Error: Could not subscribe. Please try again.";
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        final textColor = isDark ? Colors.white : Colors.black87;
        
        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: isDark ? themeProvider.darkGreyBoxColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.mark_email_read, size: 40, color: Colors.amber.shade600),
              const SizedBox(height: 10),
              Text(
                "Subscribe for Updates & Promos",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Join our community and be the first to hear about new features, massive events, and exclusive promo codes!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Enter your email address",
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _subscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("SUBSCRIBE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 15),
                Text(
                  _message,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ]
            ],
          ),
        );
      }
    );
  }
}
