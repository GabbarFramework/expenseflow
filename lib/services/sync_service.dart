import 'package:connectivity_plus/connectivity_plus.dart';
import 'expense_service.dart';
import 'local_db_service.dart';
import '../models/expense.dart';

class SyncService {
  final ExpenseService _firebaseService = ExpenseService();
  final LocalDBService _localDBService = LocalDBService();

  Future<void> syncExpenses() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    
    if (connectivityResult != ConnectivityResult.none) {
      final localExpenses = await _localDBService.getExpenses();
      
      for (var expense in localExpenses) {
        await _firebaseService.addExpense(expense);
      }
      
      await _localDBService.deleteExpense("ALL");
    }
  }
}
