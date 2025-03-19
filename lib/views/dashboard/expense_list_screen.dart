import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart'; // Import constants

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(AppConstants.expensesCollection)
            .where(AppConstants.userIdField, isEqualTo: user?.uid)
            .orderBy(AppConstants.dateField, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(AppConstants.noExpensesMessage));
          }

          final expenses = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final String title = expense[AppConstants.titleField];
              final double amount = expense[AppConstants.amountField];
              final String category = expense[AppConstants.categoryField];
              final bool isExpense = expense[AppConstants.isExpenseField];
              final Timestamp timestamp = expense[AppConstants.dateField];

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isExpense ? AppColors.expenseColor : AppColors.incomeColor,
                  ),
                  title: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "$category • ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())}",
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    "\$${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: isExpense ? AppColors.expenseColor : AppColors.incomeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onLongPress: () => _showExpenseMenu(context, expense.id, title, amount, category, isExpense, timestamp),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Show menu for Edit & Delete
  void _showExpenseMenu(BuildContext context, String expenseId, String title, double amount, String category, bool isExpense, Timestamp date) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Edit Expense'),
              onTap: () {
                Navigator.pop(context);
                _editExpense(context, expenseId, title, amount, category, isExpense, date);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Expense'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteExpense(context, expenseId);
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ Edit Expense Dialog
  void _editExpense(BuildContext context, String expenseId, String title, double amount, String category, bool isExpense, Timestamp date) {
    TextEditingController titleController = TextEditingController(text: title);
    TextEditingController amountController = TextEditingController(text: amount.toString());
    TextEditingController categoryController = TextEditingController(text: category);
    bool isExpenseType = isExpense;
    DateTime selectedDate = date.toDate();
    TextEditingController dateTimeController = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm').format(selectedDate),
    );

    Future<void> selectDateTime(BuildContext context) async {
      // Pick Date
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );

      if (pickedDate == null) return; // User canceled

      // Pick Time
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate),
      );

      if (pickedTime == null) return; // User canceled

      setState(() {
        selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        dateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(selectedDate);
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: category,
                onChanged: (newValue) {
                  categoryController.text = newValue!;
                },
                items: AppConstants.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Category'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Expense Type:"),
                  Switch(
                    value: isExpenseType,
                    onChanged: (value) {
                      isExpenseType = value;
                    },
                  ),
                ],
              ),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date & Time",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: dateTimeController,
                onTap: () => selectDateTime(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateExpense(expenseId, titleController.text, double.parse(amountController.text), categoryController.text, isExpenseType, selectedDate);
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  // ✅ Update Expense in Firestore
  void _updateExpense(String expenseId, String newTitle, double newAmount, String newCategory, bool newIsExpense, DateTime newDate) {
    _firestore.collection(AppConstants.expensesCollection).doc(expenseId).update({
      AppConstants.titleField: newTitle,
      AppConstants.amountField: newAmount,
      AppConstants.categoryField: newCategory,
      AppConstants.isExpenseField: newIsExpense,
      AppConstants.dateField: Timestamp.fromDate(newDate),
    }).then((_) {
      print("Expense updated successfully.");
    }).catchError((error) {
      print("Error updating expense: $error");
    });
  }

  // ✅ Confirm Delete Expense
  void _confirmDeleteExpense(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Expense'),
          content: Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteExpense(expenseId);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // ✅ Delete Expense from Firestore
  void _deleteExpense(String expenseId) {
    _firestore.collection(AppConstants.expensesCollection).doc(expenseId).delete().then((_) {
      print("Expense deleted successfully.");
    }).catchError((error) {
      print("Error deleting expense: $error");
    });
  }
}
