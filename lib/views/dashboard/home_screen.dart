import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'profile_screen.dart';
import 'expense_list_screen.dart';
import 'insights_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService auth = AuthService();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ExpenseListScreen(), // 📝 Expense List
    InsightsScreen(), // 📊 Expense Insights
    ProfileScreen(), // 👤 Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _signOut(BuildContext context) async {
    await auth.signOut();
    Navigator.pushReplacementNamed(context, "/landing");
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("ExpenseFlow"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _screens[_selectedIndex], // 🖥️ Load selected screen
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Expenses'), // 📄 Expense List
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Insights'), // 📊 Insights
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'), // 👤 Profile
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Highlight selected tab
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/addExpense'),
              child: Icon(Icons.add),
            )
          : null, // Hide FAB when not on Expense List
    );
  }
}
