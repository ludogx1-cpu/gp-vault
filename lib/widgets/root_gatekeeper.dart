import 'auth_dialog.dart';
import '../screens/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class RootGatekeeper extends StatelessWidget {
  const RootGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }
        if (snapshot.hasData) {
          return const MainScaffold();
        }
        return LandingPage(
          onAuthTrigger: (context, isLogin) {
            showAuthDialogGlobal(context, isLogin);
          },
        );
      },
    );
  }
}
