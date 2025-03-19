import 'package:flutter/material.dart';

class AppConstants {
  // Firestore Collections
  static const String expensesCollection = "expenses";

  // Firestore Fields
  static const String userIdField = "userId";
  static const String titleField = "title";
  static const String amountField = "amount";
  static const String categoryField = "category";
  static const String isExpenseField = "isExpense";
  static const String dateField = "date";

  // App Strings
  static const String appName = "ExpenseFlow";
  static const String noExpensesMessage = "No expenses yet. Add one!";

    // ✅ Add this missing categories list
  static const List<String> categories = [
    "Food",
    "Transport",
    "Entertainment",
    "Shopping",
    "Health",
    "Bills",
    "Salary",
    "Other"
  ];
}

class AppColors {
  static const Color primaryColor = Colors.blue;
  static const Color expenseColor = Colors.red;
  static const Color incomeColor = Colors.green;
  static const Color backgroundColor = Colors.white;
}
