import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';

class SuggestionBoxPage extends StatefulWidget {
  const SuggestionBoxPage({super.key});

  @override
  State<SuggestionBoxPage> createState() => _SuggestionBoxPageState();
}

class _SuggestionBoxPageState extends State<SuggestionBoxPage> {
  final TextEditingController _suggestionController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitSuggestion() async {
    final text = _suggestionController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('suggestions').add({
        'uid': user?.uid ?? 'anonymous',
        'email': user?.email ?? 'anonymous',
        'suggestion': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _suggestionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thank you! Your suggestion has been submitted successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting suggestion: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      drawer: const AppDrawer(),
      body: ListenableBuilder(
        listenable: themeProvider,
        builder: (context, _) {
          final isDark = themeProvider.isDarkMode;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? themeProvider.darkGreyBoxColor : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? themeProvider.darkGreyBorder : Colors.blue.shade200,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 64,
                      color: isDark ? Colors.blueAccent : Colors.blue.shade800,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Suggestion Box",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.blueAccent : Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Have an idea to improve Golden Paw? Let us know! We read every submission.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _suggestionController,
                      maxLines: 6,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your suggestion here...",
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.blue.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.blue.shade200,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitSuggestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.blueAccent : Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "SUBMIT SUGGESTION",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
