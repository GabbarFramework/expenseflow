import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory { food, transport, bills, entertainment, shopping, health, salary, other }

class Expense {
  String id;
  ExpenseCategory category;
  double amount;
  DateTime date;
  String note;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
  });

  // Convert Expense to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'category': category.name,  // 🔥 Store category as its name (not full enum path)
      'amount': amount,
      'date': date, // Firestore will automatically store it as a Timestamp
      'note': note,
    };
  }


  // Convert Firestore document to Expense object
  // Convert Firestore document to Expense object
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String categoryString = (data['category'] ?? '').toLowerCase(); // 🔥 Normalize case
    print("🔥 Firestore Data: ${doc.id} -> category: $categoryString"); // Debug log

    return Expense(
      id: doc.id,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == categoryString,  // ✅ Match lowercase enum name
        orElse: () {
          print("⚠️ Unknown category: $categoryString, defaulting to 'other'");
          return ExpenseCategory.other;
        },
      ),
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      note: data['title'] ?? '',
    );
  }
}
