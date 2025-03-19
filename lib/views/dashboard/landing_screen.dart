import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class LandingScreen extends StatelessWidget {
  final AuthService authService = AuthService();

  LandingScreen({super.key});

  void signInWithGoogle(BuildContext context) async {
    var user = await authService.signInWithGoogle();
    if (user != null) {
      print("Google Sign-In Success: ${user.email}");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print("Google Sign-In Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome to ExpenseFlow", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())),
                child: Text("Login with Email"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen())),
                child: Text("Sign Up with Email"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => signInWithGoogle(context),
                child: Text("Sign in with Google"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
