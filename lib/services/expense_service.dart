import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addExpense(Expense expense) async {
    await _db.collection('expenses').doc(expense.id).set(expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    try {
      var snapshot = await _db.collection('expenses').get();
      print("Fetched ${snapshot.docs.length} expenses from Firestore.");

      return snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching expenses: $e");
      return [];
    }
  }

  Future<void> deleteExpense(String id) async {
    await _db.collection('expenses').doc(id).delete();
  }
}
